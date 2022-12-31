import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/cache_bag.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:archive/archive_io.dart';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import '../data_models/city.dart';
import '../data_models/event.dart';
import '../utils/util.dart';

final CacheService cacheService = CacheService._instance;

class CacheParameters {
  late SendPort sendPort;
  late String url;
  late bool useCacheService = true;
  late int minutesAgo;
  late String cityId;

  CacheParameters({
    required this.sendPort,
    required this.url,
    required this.cityId,
    required this.minutesAgo,
    required this.useCacheService,
  });
}

class CacheMessage {
  late String message;
  late int statusCode;
  late int type;
  late String date;
  late double? elapsedSeconds;
  late String? cities, places, events, aggregates, dashboards;
  late Map<String, dynamic>? cacheBagJson;

  CacheMessage(
      {required this.message,
      required this.statusCode,
      required this.date,
      required this.elapsedSeconds,
      required this.type,
      this.cacheBagJson,
      this.cities,
      this.places,
      this.events,
      this.aggregates,
      this.dashboards});

  CacheMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    type = json['type'];
    statusCode = json['statusCode'];
    date = json['date'];
    elapsedSeconds = json['elapsedSeconds'];
    cities = json['cities'];
    places = json['places'];
    events = json['events'];
    aggregates = json['aggregates'];
    dashboards = json['dashboards'];
    cacheBagJson = json['cacheBagJson'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'elapsedSeconds': elapsedSeconds,
        'message': message,
        'date': date,
        'type': type,
        'statusCode': statusCode,
        'cities': cities,
        'places': places,
        'events': events,
        'dashboards': dashboards,
        'aggregates': aggregates,
        'cacheBagJson': cacheBagJson,
      };
}

const typeMessage = 0,
    typeCity = 1,
    typePlace = 2,
    typeEvent = 3,
    typeAggregate = 4,
    typeDashboard = 5,
    typeCacheBag = 6;

const statusBusy = 201, statusDone = 200, statusError = 500;

class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal() {
    // initialization logic
  }

  var cities = <City>[];
  var places = <CityPlace>[];
  var start = 0;
  final numberFormat = NumberFormat.compact();

  static late SendPort sendPort;
  static late CacheParameters cacheParameters;

  void startCaching({required CacheParameters params}) async {
    sendPort = params.sendPort;
    cacheParameters = params;

    p('\n\n${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: .......... preparing remote data for storing in local hive cache ...');
    start = DateTime.now().millisecondsSinceEpoch;

    int minutesAgo = cacheParameters.minutesAgo;
    p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
          ' CacheService: .......... preparing remote data from $minutesAgo minutesAgo ago ...');
    if (minutesAgo == 0) {
      p('${Emoji.brocolli}${Emoji.brocolli} cacheService: minutesAgo: $minutesAgo - is zero, quitting!');
      var msg = CacheMessage(
          message: "${Emoji.leaf} No need to cache",
          statusCode: statusDone,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: 0.0,
          type: typeMessage);
      p('${Emoji.brocolli}${Emoji.brocolli} cacheService: sending minutesAgo is ZERO; over the sendPort ...');
      sendPort.send(msg.toJson());
      return;
    }

    await _executeDataSearch();

    p('\n\n${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed}'
        ' CacheService: caching complete!\n\n');
  }

  Future<CacheBag?> _executeDataSearch() async {
    var client = http.Client();
    var suffix1 = 'getDataForCache?minutesAgo=${cacheParameters.minutesAgo}';
    var fullUrl = '';
    CacheBag? cacheBag;
    fullUrl = '${cacheParameters.url}$suffix1';
    var start = DateTime.now().millisecondsSinceEpoch;

    p("$heartOrange _getDataForCaching: HTTP Url: $fullUrl");
    var response = await client
        .get(Uri.parse(fullUrl))
        .timeout(const Duration(seconds: 9000));

    printStatusCode(response);
    var end = DateTime.now().millisecondsSinceEpoch;
    double elapsed = _printElapsed(end, start, fullUrl);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      cacheBag = CacheBag.fromJson(data);
      cacheBag.elapsedSeconds = elapsed;

      _printCacheBag(cacheBag);

      var msg = CacheMessage(
          message: "${Emoji.blueDot} cacheBag sent over",
          statusCode: statusBusy,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: elapsed,
          type: typeCacheBag,
          cacheBagJson: cacheBag.toJson());

      p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: sending cacheBag over the sendPort ...');
      sendPort.send(msg.toJson());

      _sendCacheBagMessages(cacheBag, elapsed);

      p('${Emoji.brocolli}${Emoji.brocolli} cacheService: other data except events processed');
    } else {
      p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
      var e = Exception(
          'Server could not handle request, status: ${response.statusCode} - ${response.body}');
      _handleError(e, '_getDataForCaching');
    }
    return null;
  }

  void _sendCacheBagMessages(CacheBag cacheBag, double elapsed) {
    var fm = NumberFormat.decimalPattern();
    var msg1 = CacheMessage(
        message: "${cacheBag.cities.length} cities",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: typeMessage);
    sendPort.send(msg1.toJson());

    var msg2 = CacheMessage(
        message: "${fm.format(cacheBag.places.length)} places",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: typeMessage);
    sendPort.send(msg2.toJson());

    var msg3 = CacheMessage(
        message: "${cacheBag.dashboards.length} dashboards",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: typeMessage);
    sendPort.send(msg3.toJson());

    var msg4 = CacheMessage(
        message: "${fm.format(cacheBag.aggregates.length)} aggregates",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: typeMessage);
    sendPort.send(msg4.toJson());

    var msg6 = CacheMessage(
        message: "${cacheBag.elapsedSeconds} seconds elapsed",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: typeMessage);
    sendPort.send(msg6.toJson());
  }

  static void _printCacheBag(CacheBag bag) {
    p('\n${Emoji.blueDot}${Emoji.blueDot} CacheBag: date: ${bag.date} cities: ${bag.cities.length} '
        'places: ${bag.places.length} dashboards: ${bag.dashboards.length} '
        'aggregates: ${bag.aggregates.length} ');
    p('${Emoji.blueDot}${Emoji.blueDot} CacheBag: Call took: ${bag.elapsedSeconds} seconds to execute ${Emoji.blueDot}\n');
  }

  static void printStatusCode(http.Response response) {
    p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: We have a response from the DataDriver API! $heartOrange '
        'statusCode: ${response.statusCode}');
  }

  static double _printElapsed(int end, int start, String url) {
    var elapsed = (end - start) / 1000;
    p('\n${Emoji.brocolli}${Emoji.brocolli}${Emoji.brocolli} CacheService: '
        ' elapsed time for network call: $url $heartOrange '
        ' $elapsed seconds ${Emoji.brocolli}${Emoji.brocolli}\n');
    return elapsed;
  }

  static void _handleError(dynamic e, String method) {
    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Method: $method - Things got a little troubled!  $blueDot error: $e');

    var msg = CacheMessage(
      message: "$e",
      statusCode: statusError,
      date: DateTime.now().toIso8601String(),
      elapsedSeconds: 0,
      type: typeMessage,
    );
    sendPort.send(msg.toJson());
  }

  static Future<String>? _downloadCityEventsFile(
      {required String url, required String path}) async {
    var msg = CacheMessage(
        message: "${Emoji.appleGreen} Getting zipped file ...",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: 0,
        type: typeMessage);
    sendPort.send(msg.toJson());
    //
    io.HttpClient client = io.HttpClient();
    client.autoUncompress = true;
    client.connectionTimeout = const Duration(minutes: 30);

    var m = 'getFileStream?filename=$path';
    var mUrl = Uri.parse('$url$m');
    p('🥦🥦🥦🥦 🔴 _getDataInOptimizedManner: url to download zipped file:: $mUrl');

    final downloadData = <int>[];
    final start = DateTime.now().millisecondsSinceEpoch;

    client.getUrl(mUrl).then((HttpClientRequest request) {
      p('\n🍏🍏HttpClient getUrl then: ... closing request, method:: ${request.method}');
      return request.close();
    }).then((HttpClientResponse response) {
      p('🍏🍏HttpClientResponse statusCode: ${response.statusCode} 🍏 contentLength: ${response.contentLength} '
          ' 🍏compressionState: ${response.compressionState}');

      response.listen((d) => downloadData.addAll(d), onDone: () async {
        p('🔴🔴🔴 onDone fired! 🍏downloadData is ready: ${fm.format(downloadData.length)} bytes long, '
            'will call _handleZippedFile ');
        await _handleZippedFile(downloadData, start);
      });
    });

    return "Work done!";
  }

  static final fm = NumberFormat.compact();

  static Future _handleZippedFile(List<int> downloadData, int start) async{
    p('\n\n${Emoji.blueDot}${Emoji.blueDot} CacheService: _handleZippedFile starting ...'
        'downloadData: ${downloadData.length} bytes');
    var events = <Event>[];

    try {
      var zipArchive = ZipDecoder().decodeBytes(downloadData);
      p('🔴🔴🔴 ZippedArchive files: ${zipArchive.files.length}');
      for (var file in zipArchive) {
        p('🔴🔴🔴 File found in archive: ${file.name} isCompressed: ${file.isCompressed},'
            ' file size: ${file.size / 1024} MB');
        if (file.isFile) {
          final data = file.content as List<int>;
          var jsonString = String.fromCharCodes(data);
          List tagsJson = jsonDecode(jsonString);
          for (var mJson in tagsJson) {
            var event = Event.fromJson(mJson);
            events.add(event);
          }

          p('🔴🔴🔴 Unzipped json string is: ${fm.format(jsonString.length)} bytes long ');
        }
      }

      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsed = (end - start) / 1000;

      p('🔴🔴🔴 Total events from zipped file: ${fm.format(events.length)}  ');
      //break apart the events into batches
      const batchSize = 50000;
      if (events.length > batchSize) {
        int rem = events.length % batchSize;
        int batches = events.length ~/ batchSize;
        if (rem > 0) {
          batches++;
        }
        p('\n\n${Emoji.leaf}${Emoji.leaf} $batches batches of events to send ..');
        for (var i = 0; i < batches; i++) {
          var end = 0;
          if (batchSize * (i + 1) > events.length) {
            end = events.length;
          } else {
            end = batchSize * (i + 1);
          }
          try {
            var list = events.sublist(i * batchSize, end);
            p('${Emoji.leaf}${Emoji.leaf} Sending batch #${i + 1} of ${list.length} '
                'events to send over sendPort ...');
            _sendEventsBag(elapsed, list);
          } catch (e) {
            p('...... check if range error .. $e');
            var list = events.sublist(i * batchSize, events.length);
            if (e.toString().contains('RangeError')) {
              p('${Emoji.leaf}${Emoji.leaf} Sending batch #${i + 1} of ${list.length} '
                  'events to send over sendPort ...');
              _sendEventsBag(elapsed, list);
            }
          }
        }
      } else {
        p('\n\n${Emoji.leaf}${Emoji.leaf} Sending one batch of ${events.length} '
            'events to send over sendPort ...\n');
        _sendEventsBag(elapsed, events);
      }
      var msg = CacheMessage(
          message: "${Emoji.appleGreen} Processed zipped file",
          statusCode: statusDone,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: elapsed,
          type: typeMessage);
      sendPort.send(msg.toJson());

      var end2 = DateTime.now().millisecondsSinceEpoch;
      var secs = (end2 - start) / 1000;

      p('\n${Emoji.brocolli} ${Emoji.brocolli} cacheService: '
          ' ${Emoji.blueDot} finished processing events from zipped file downloaded; '
          'elapsed; $secs seconds\n');
    } catch (e) {
      p(' 🔴🔴 $e  🔴🔴');
      _handleError(e, '_handleZippedFile');
    }
  }

  static void _sendEventsBag(double elapsed, List<Event> list) {
    var bag = CacheBag(
        cities: [],
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        places: [],
        dashboards: [],
        aggregates: [],
        events: list);
    //send batch ...
    var ms = CacheMessage(
        message: '🔴 ${fm.format(list.length)} Events returned',
        statusCode: PROCESSED_EVENTS,
        date: DateTime.now().toIso8601String(),
        cacheBagJson: bag.toJson(),
        elapsedSeconds: elapsed,
        type: typeEvent);

    p('🔴 Sending events inside cacheBag over sendPort '
        '${Emoji.blueDot} : ${list.length} events; after waiting for 3 seconds');
    sendPort.send(ms.toJson());
  }

   Future<void> cacheCityEvents(
      {required CacheParameters parameters}) async {
    cacheParameters = parameters;
    sendPort = parameters.sendPort;
    p('🥦🥦🥦🥦🥦🥦🥦🥦 cacheCityEvents starting ..., with prefix: ${parameters.url}');
    var msg = CacheMessage(
        message: "${Emoji.appleGreen} requesting zipped files",
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: 0,
        type: typeMessage);
    sendPort.send(msg.toJson());
    //
    var start = DateTime.now().millisecondsSinceEpoch;
    var httpClient = http.Client();
    var m = "getEventZippedFilePath?minutesAgo=${parameters.minutesAgo}&cityId=${parameters.cityId}";
    var mUrl = Uri.parse('${parameters.url}$m');
    p('🥦🥦🥦🥦🥦🥦 cacheCityEvents: http url: $mUrl');

    var response = await httpClient.get(mUrl);

    printStatusCode(response);
    String? path;
    if (response.statusCode == 200) {
      path = response.body;
      var end = DateTime.now().millisecondsSinceEpoch;
      var secs = (end - start) / 1000;
      p('🔴🔴 path of zip file to download: $path  🔴🔴 elapsed seconds: $secs');
      var msg2 = CacheMessage(
          message: "${Emoji.appleGreen} Obtained file path",
          statusCode: statusBusy,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: secs,
          type: typeMessage);

      sendPort.send(msg2.toJson());
    } else {
      var end = DateTime.now().millisecondsSinceEpoch;
      var secs = (end - start) / 1000;
      p(' 🔴🔴 bad response: ${response.statusCode} - ${response.body}  🔴🔴 elapsed seconds: $secs');
      var msg2 = CacheMessage(
          message: "${Emoji.redDot} Error: statusCode: ${response.statusCode}",
          statusCode: statusBusy,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: secs,
          type: typeMessage);

      sendPort.send(msg2.toJson());
    }
    if (path != null) {
      var res = await _downloadCityEventsFile(url: parameters.url, path: path);
      p(res);
    }

    return ;
  }
}
