import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/screens/main_screen.dart';

void main() async {
  // Ensures that Flutter is fully initialized before using async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the Flutter application
  runApp(const MyApp());
}

/// Root widget 
class MediMindApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // to hide debug banner in the corner
      debugShowCheckedModeBanner: false,
      // Set MainScreen as the initial screen
      home: MainScreen(),
    );
  }
}