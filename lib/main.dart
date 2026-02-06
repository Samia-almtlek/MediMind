import 'package:flutter/material.dart';
import 'presentation/screens/splash_screen.dart';

/// Entry point for the app
void main() {
  runApp(MediMindApp());
}

/// Root widget 
class MediMindApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // to hide debug banner in the corner
      debugShowCheckedModeBanner: false,
      // Set SplashScreen as the initial screen
      home: SplashScreen(),
    );
  }
}