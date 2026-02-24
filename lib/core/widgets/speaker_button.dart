import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
class SpeakerButton extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;

  static final FlutterTts _tts = FlutterTts();

  const SpeakerButton({
    super.key,
    required this.text,
    this.size = 20,
    this.color,
  });

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> _speak() async {
    await _tts.stop(); // 🔥 يوقف أي صوت سابق أولاً
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.volume_up, size: size, color: color),
      onPressed: _speak,
    );
  }
}