import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  TTSService._();
  static final TTSService instance = TTSService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await init();

    // 🔥 Always stop before speaking
    await _flutterTts.stop();

    await _flutterTts.speak(text);
  }

  Future<void> stopIfSpeaking() async {
    await _flutterTts.stop();
  }
}