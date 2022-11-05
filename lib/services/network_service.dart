import 'dart:convert';

import 'package:datadriver_mobile/emojis.dart';
import 'package:datadriver_mobile/services/util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpService {
  late http.Client client;
  HttpService() {
    p('$heartOrange $heartOrange  HttpService constructed');
    client = http.Client();
    p('$heartOrange $heartOrange  http.Client created:  ${client.toString()}');
  }

  Future<String?> generateEvents(
      {required int intervalInSeconds, required int upperCountPerPlace, required int maxCount}) async {
    var url = dotenv.env['DEV_URL'];
    var suffix1 = 'generateEvents?intervalInSeconds=$intervalInSeconds';
    var suffix2 = '&upperCountPerPlace=$upperCountPerPlace';
    var suffix3 = '&maxCount=$maxCount';
    if (url != null) {
      url += '$suffix1$suffix2$suffix3';
      p("$heartOrange $heartOrange HTTP Url: $url");
    } else {
      throw Exception("URL parameter not found");
    }

    // url = 'http://localhost:8094/generateEvents?intervalInSeconds=10&upperCountPerPlace=50&maxCount=20000';
    //client ??= http.Client();
    p("$heartOrange $heartOrange Network Client created  $brocolli ${client.toString()}");
    try {
      var response = await client.get(Uri.parse(url));
      p('$brocolli $brocolli We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        var decodedResponse = response.body;
        p('$brocolli $brocolli HttpService: decodedResponse: $decodedResponse');
        if (kDebugMode) {
          p('$heartOrange $heartOrange $decodedResponse');
        }
        return decodedResponse;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $e');
      throw Exception('$redDot $redDot $redDot Network shit screwed up! $e');
    }
    return null;
  }

  Future<String?> stopGenerator() async {
    var url = dotenv.env['DEV_URL'];
    var suffix1 = 'stopGenerator';

    if (url != null) {
      url += suffix1;
      p("$heartOrange $heartOrange stopGenerator HTTP Url: $url");
    } else {
      throw Exception("URL parameter not found");
    }

    // url = 'http://localhost:8094/generateEvents?intervalInSeconds=10&upperCountPerPlace=50&maxCount=20000';
    //client ??= http.Client();
    p("$heartOrange $heartOrange Network Client created  $brocolli ${client.toString()}");
    try {
      var response = await client.get(Uri.parse(url));
      p('$brocolli $brocolli We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        var decodedResponse = response.body;
        p('$brocolli $brocolli HttpService: decodedResponse: $decodedResponse');
        if (kDebugMode) {
          p('$heartOrange $heartOrange $decodedResponse');
        }
        return decodedResponse;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $e');
      throw Exception('$redDot $redDot $redDot Network shit screwed up! $e');
    }
    return null;
  }
}
