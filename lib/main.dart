import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Removes the "DEBUG" banner from the top-right corner
      debugShowCheckedModeBanner: false,

      // Application title
      title: 'MediMind',

      // Temporary screen (we will replace this with AuthGate next)
      home: Placeholder(),
    );
  }
}
