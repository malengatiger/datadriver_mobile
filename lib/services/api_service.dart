import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../data_models/city_aggregate.dart';
import '../data_models/generation_message.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

abstract class AbstractApiService {
  Future<List<DashboardData>> getDashboardData({required int minutesAgo});
  Future<GenerationMessage?> generateEventsByCity(
      {required String cityId, required int count});
  Future<List<CityAggregate>> getCityAggregates({required int minutesAgo});
  Future<List<GenerationMessage>> generateEventsByCities(
      {required List<String> cityIds, required int upperCount});
  Future<DashboardData> addDashboardData({required int minutesAgo});
}

class ApiService implements AbstractApiService {
  late http.Client client;
  String? url, currentStatus;
  ApiService() {
    p('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot} HttpService constructed');
    client = http.Client();
    setStatus();
  }

  void setStatus() {
    currentStatus = dotenv.env['CURRENT_STATUS'];
    if (currentStatus == 'dev') {
      url = dotenv.env['DEV_URL']!;
    }
    if (currentStatus == 'prod') {
      url = dotenv.env['PROD_URL']!;
    }
    // p('${Emoji.redDot} HttpService url: $url');
  }

  @override
  Future<List<GenerationMessage>> generateEventsByCities(
      {required List<String> cityIds, required int upperCount}) async {
    var results = <GenerationMessage>[];
    var buf = StringBuffer();
    var cnt = 0;
    for (var element in cityIds) {
      buf.write(element);
      if (cnt < cityIds.length - 1) {
        buf.write(',');
      }
      cnt++;
    }

    var suffix1 = 'generateEventsByCities?cityIds=${buf.toString()}';
    var suffix2 = '&upperCount=$upperCount';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1$suffix2';
    } else {
      throw Exception('Url from .env not found');
    }
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;
      var response = await client.get(Uri.parse(fullUrl));
      _handleElapsed(response, start);
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        results = List<GenerationMessage>.from(
            l.map((model) => GenerationMessage.fromJson(model)));
        return results;
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handlee request: ${response.body}');
      }
    } catch (e) {
      _handleException(e);
    }
    return [];
  }

  @override
  Future<GenerationMessage> generateEventsByCity(
      {required String cityId, required int count}) async {
    var suffix1 = 'generateEventsByCity?cityId=$cityId';
    var suffix2 = '&count=$count';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1$suffix2';
    } else {
      throw Exception('Url from .env not found');
    }
    GenerationMessage? msg;
    var start = DateTime.now().millisecondsSinceEpoch;
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      _handleElapsed(response, start);
      if (response.statusCode == 200) {
        var body = response.body;
        msg = GenerationMessage.fromJson(jsonDecode(body));
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handlee request: ${response.body}');
      }
    } catch (e) {
      _handleException(e);
    }
    return msg!;

  }

  @override
  Future<List<CityAggregate>> getCityAggregates({required int minutesAgo}) async {
    p('$appleGreen ... apiService getting aggregates ...');
    var results = <CityAggregate>[];
    setStatus();
    var suffix1 = 'getCityAggregates?minutesAgo=$minutesAgo';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1';
    } else {
      throw Exception('Url from .env not found');
    }
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      _handleElapsed(response, start);
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        results = List<CityAggregate>.from(
            l.map((model) => CityAggregate.fromJson(model)));

      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleException(e);
    }
    return results;
  }

  @override
  Future<List<DashboardData>> getDashboardData({required int minutesAgo}) async {
    p('$appleGreen ... apiService getting DashboardData ...');
    var results = <DashboardData>[];
    setStatus();
    var suffix1 = 'getDashboardData?minutesAgo=$minutesAgo';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1';
    } else {
      throw Exception('Url from .env not found');
    }
    try {
      p("$heartOrange getDashboardData: Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      _handleElapsed(response, start);

      if (response.statusCode == 200) {
        Iterable dashboardJson = json.decode(response.body);
        results = List<DashboardData>.from(
            dashboardJson.map((model) => DashboardData.fromJson(model)));
        return results;
      } else {
        p('${Emoji.redDot} ApiService: Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleException(e);
    }
    return [];
  }


  void _handleException(Object e) {
    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} ApiService: Things got a little fucked up! $e');
    p(e);
    if ('$e'.contains('Connection refused')) {
      throw Exception('${Emoji.redDot} Server is not available! \n\nPlease try again later!');
    } else {
      throw Exception('${Emoji.redDot} Problem with the network\n\nPlease try again later! $e');
    }
  }

  @override
  Future<DashboardData> addDashboardData({required int minutesAgo}) async {
    p('$appleGreen ... apiService adding DashboardData ...');
    DashboardData? dashData;
    setStatus();
    var suffix1 = 'addDashboardData?minutesAgo=$minutesAgo';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1';
    } else {
      throw Exception('Url from .env not found');
    }
    try {
      p("$heartOrange addDashboardData: Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      _handleElapsed(response, start);
      if (response.statusCode == 200) {
        Map<String, dynamic> dashboardJson = json.decode(response.body);
        dashData = DashboardData.fromJson(dashboardJson);

      } else {
        p('${Emoji.redDot} ApiService: Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleException(e);
    }
    return dashData!;
  }

  void _handleElapsed(http.Response response, int start) {
    p('${Emoji.brocolli} ${Emoji.brocolli} We have a response from the DataDriver API! '
        '$heartOrange statusCode: ${response.statusCode} ');
    var end = DateTime.now().millisecondsSinceEpoch;
    var elapsed = (end - start)/1000;
    p('${Emoji.brocolli} ${Emoji.brocolli} Elapsed time: ${elapsed.toStringAsFixed(2)} seconds for network call');
  }
}

// final apiProvider = Provider<ApiService>((ref) => ApiService());

class GenerateEventsByCityParams {
  late String cityId;
  late int count;

  GenerateEventsByCityParams(this.cityId, this.count);
}
