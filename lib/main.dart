import 'package:flutter/material.dart';
import 'auth/presentation/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/presentation/screens/register_screen.dart';

/// Entry point for the app


Future<void> main() async {
  // Ensures that Flutter is fully initialized before using async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized successfully');
  // Start the Flutter application
  runApp(const MediMindApp());
}

/// Root widget
class MediMindApp extends StatelessWidget {
  const MediMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hide debug banner
      debugShowCheckedModeBanner: false,
  // Set SplashScreen as the initial screen
  home:  AuthGate(),

   routes: {
        '/signup': (context) => const RegisterScreen(),
      },
      
    );
  }
}
