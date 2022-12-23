import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_frontend/data_models/cache_config.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/util.dart';

class SharedPrefs {

  static Future<int> getMinutesAgo() async {
    var config = await getConfig();
    var minutes = 60*1000*60*24;
    if (config != null) {
      var nowMilliSeconds = DateTime
          .now()
          .millisecondsSinceEpoch;
      var thenMs = config.longDate;
      var deltaMs = nowMilliSeconds - thenMs;
      minutes = (deltaMs/1000)~/60;
      p('${Emoji.heartGreen} SharedPrefs config retrieved, ${Emoji.heartGreen} '
          'minutes calculated: $minutes - ${config.toJson()}');
    }
    p('${Emoji.heartGreen} SharedPrefs config retrieved; ${Emoji.heartGreen} '
        ' default minutes used: $minutes ');

    return minutes;
  }

  static Future saveConfig(CacheConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    var source = config.toJson();
    var jsonString = jsonEncode(source);
    await prefs.setString("cacheConfig", jsonString);

    p('${Emoji.heartGreen} SharedPrefs config cached; ${Emoji.heartGreen} '
        ' date: ${config.stringDate} ');
  }

  static Future deleteConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("cacheConfig");

    p('${Emoji.redDot} SharedPrefs config deleted; ${Emoji.redDot} ');
  }

  static Future<CacheConfig?> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString("cacheConfig");
    if (jsonString != null) {
      var mJson = jsonDecode(jsonString);
      var config = CacheConfig.fromJson(mJson);
      p('${Emoji.heartGreen} SharedPrefs config retrieved; ${Emoji.heartGreen} ');
      return config;
    }
    p('${Emoji.redDot} SharedPrefs no config found; ${Emoji.redDot} ');

    return null;
  }
}