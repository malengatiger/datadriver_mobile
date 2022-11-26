import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emojis.dart';

p(dynamic message) {
  if (message is String) {
    debugPrint(message);
  } else {
    print(message);
  }
}

late SharedPreferences prefs;
setSharedPrefs() async {
  prefs = await SharedPreferences.getInstance();
  p('$heartGreen  SharedPreferences has been set');
}

setEmail(String email) {
  prefs.setString('email', email);
}

String? getEmail() {
  return prefs.getString('email');
}

setPassword(String email) {
  prefs.setString('password', email);
}

String? getPassword() {
  return prefs.getString('password');
}

// Save an integer value to 'counter' key.
// await prefs.setInt('counter', 10);
// // Save an boolean value to 'repeat' key.
// await prefs.setBool('repeat', true);
// // Save an double value to 'decimal' key.
// await prefs.setDouble('decimal', 1.5);
// // Save an String value to 'action' key.
// await prefs.setString('action', 'Start');
// // Save an list of strings to 'items' key.
// await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);
