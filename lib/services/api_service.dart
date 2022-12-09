import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../data_models/city_aggregate.dart';
import '../data_models/generation_message.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

abstract class AbstractApiService {
  Future<DashboardData?> getDashboardData({required int minutesAgo});
  Future<GenerationMessage?> generateEventsByCity(
      {required String cityId, required int count});
  Future<List<CityAggregate>> getCityAggregates({required int minutes});
  Future<List<GenerationMessage>> generateEventsByCities(
      {required List<String> cityIds, required int upperCount});
}

class ApiService implements AbstractApiService {
  late http.Client client;
  String? url, currentStatus;
  ApiService() {
    p('$heartOrange $heartOrange  HttpService constructed');
    client = http.Client();
    p('$heartOrange $heartOrange  http.Client created:  ${client.toString()}');
    setStatus();
  }

  void setStatus() {
    p('$heartOrange $heartOrange  setting current status  ...');
    currentStatus = dotenv.env['CURRENT_STATUS'];
    if (currentStatus == 'dev') {
      url = dotenv.env['DEV_URL']!;
    }
    if (currentStatus == 'prod') {
      url = dotenv.env['PROD_URL']!;
    }
    p('$redDot HttpService url: $url');
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
      var response = await client.get(Uri.parse(fullUrl));
      p('${Emoji.brocolli} ${Emoji.brocolli} We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        results = List<GenerationMessage>.from(
            l.map((model) => GenerationMessage.fromJson(model)));
        return results;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handlee request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
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
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      p('${Emoji.brocolli} ${Emoji.brocolli} We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        var body = response.body;
        var msg = GenerationMessage.fromJson(jsonDecode(body));
        return msg;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handlee request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
  }

  @override
  Future<List<CityAggregate>> getCityAggregates({required int minutes}) async {
    p('$appleGreen ... apiService getting aggregates ...');
    var results = <CityAggregate>[];
    setStatus();
    var suffix1 = 'getCityAggregates?minutes=$minutes';
    var fullUrl = '';
    if (url != null) {
      fullUrl = '$url$suffix1';
    } else {
      throw Exception('Url from .env not found');
    }
    try {
      p("$heartOrange HTTP Url: $fullUrl");

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      p('${Emoji.brocolli} ${Emoji.brocolli} We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode} ');

      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        results = List<CityAggregate>.from(
            l.map((model) => CityAggregate.fromJson(model)));
        return results;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
  }

  @override
  Future<DashboardData?> getDashboardData({required int minutesAgo}) async {
    p('$appleGreen ... apiService getting aggregates ...');
    DashboardData? results;
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
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 120));
      p('${Emoji.brocolli} ${Emoji.brocolli} We have a response from the DataDriver API! '
          '$heartOrange statusCode: ${response.statusCode} body: ${response.body} ');

      if (response.statusCode == 200) {
        results = DashboardData.fromJson(json.decode(response.body));
        return results;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
  }
}

// final apiProvider = Provider<ApiService>((ref) => ApiService());

class GenerateEventsByCityParams {
  late String cityId;
  late int count;

  GenerateEventsByCityParams(this.cityId, this.count);
}
