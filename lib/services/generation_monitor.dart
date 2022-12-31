import 'dart:async';

import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../utils/util.dart';

final GenerationMonitor generationMonitor = GenerationMonitor._instance;

class GenerationMonitor {
  static final GenerationMonitor _instance = GenerationMonitor._internal();

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory GenerationMonitor() {
    return _instance;
  }

  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  GenerationMonitor._internal() {
    // initialization logic
  }

  final StreamController<TimerMessage> _controller =
      StreamController.broadcast();
  Stream<TimerMessage> get timerStream => _controller.stream;

  final StreamController<String> _controller2 = StreamController.broadcast();
  Stream<String> get cancelStream => _controller2.stream;

  void addMessage(TimerMessage timerMessage) {
    p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen} '
        'GenerationMonitor: adding timer message to stream timerStream ...');

    _controller.sink.add(timerMessage);
  }

  void sendStopMessage() {
    p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen} '
        'GenerationMonitor: adding stop timer message to stream ...');
    _controller2.sink.add('Stop');
  }
}
