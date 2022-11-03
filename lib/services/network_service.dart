import 'dart:convert';

import 'package:datadriver_mobile/services/util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpService {


  late http.Client client;
  Future<String> getEvents() async {
    var url = dotenv.env['VAR_NAME'];
    if (url != null) {
      url += "getEvents";
      p("Url prefix is $url");
    } else {
      throw Exception("URL parameter not found");
    }

    client ??= http.Client();
    p("Network Client created");
    try {
      var response = await client.get(
          Uri.https(url));
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      var uri = Uri.parse(decodedResponse['uri'] as String);
      var result = await client.get(uri);
      if (kDebugMode) {
        print(result);
      }
      var body = result.body;
      p(body);
      return result.body;
    } finally {
    client.close();
    }
  }
}