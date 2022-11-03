import 'package:flutter/cupertino.dart';

p (dynamic message) {
  if (message is String) {
    debugPrint(message);
  } else {
    print(message);
  }
}