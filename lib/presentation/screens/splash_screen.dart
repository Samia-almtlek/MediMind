import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import '../../auth/presentation/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _appName = 'MediMind';
  static const Duration _splashDuration = Duration(seconds: 2);
  static const Duration _typingStep = Duration(milliseconds: 140);
  static const Duration _cursorBlink = Duration(milliseconds: 450);

  Timer? _typingTimer;
  Timer? _cursorTimer;
  int _visibleChars = 0;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _playStartupHeartbeat();

    _typingTimer = Timer.periodic(_typingStep, (timer) {
      if (!mounted) return;

      if (_visibleChars < _appName.length) {
        setState(() => _visibleChars++);
      } else {
        timer.cancel();
      }
    });

    _cursorTimer = Timer.periodic(_cursorBlink, (_) {
      if (!mounted) return;
      setState(() => _showCursor = !_showCursor);
    });

    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  Future<void> _playStartupHeartbeat() async {
    await SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 170));
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final logoSize = (shortestSide * 0.28).clamp(100.0, 170.0);
    final logoCacheSize = (logoSize * pixelRatio).round();
    final nameFontSize = (shortestSide * 0.10).clamp(28.0, 42.0);
    final typedName = _appName.substring(0, _visibleChars);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  isAntiAlias: true,
                  filterQuality: FilterQuality.high,
                  cacheWidth: logoCacheSize,
                  cacheHeight: logoCacheSize,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: nameFontSize * 1.5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iconGrey,
                        letterSpacing: 0.3,
                      ),
                      children: [
                        TextSpan(text: typedName),
                        TextSpan(
                          text: _showCursor ? '|' : ' ',
                          style: const TextStyle(color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}