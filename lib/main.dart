import 'package:flutter/material.dart';
import 'auth/presentation/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'auth/presentation/screens/register_screen.dart';

import 'presentation/screens/medications_screen.dart';
import 'presentation/screens/medical_id_screen.dart';
import 'presentation/screens/support_screen.dart';
import 'presentation/screens/privacy_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/notification_settings_screen.dart';

/// Entry point for the app

Future<void> main() async {
  /// Ensures that Flutter bindings are initialized
  /// before calling any asynchronous code.
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔥 Firebase initialized successfully');

  /// Initialize Hive (local key-value database)
  /// Hive is a pure Dart solution and does not depend on
  /// Android / iOS build tools.
  await Hive.initFlutter();

  /// Open a Hive box to store medication names locally.
  /// We only store Strings (drug names) for autocomplete.
  await Hive.openBox<String>('drugs');

  // Search the main() function and add the box
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Add the following: the box for medical ID (we use a dynamic box for different types)
  await Hive.openBox('medical_id_data');
  // Add the following: the box for medication stock (we use a Map to store drug name and quantity)
  await Hive.openBox<Map>('medication_stock');

  print('🗄️ Hive initialized successfully');

  runApp(const MediMindApp());
}

/// Root widget of the application
class MediMindApp extends StatelessWidget {
  const MediMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// Hide the debug banner
      debugShowCheckedModeBanner: false,

      // Set SplashScreen as the initial screen
      home: AuthGate(),
      routes: {
        '/signup': (context) => const RegisterScreen(),
        '/medications': (context) => MedicationsScreen(),
        '/medical_id': (context) => MedicalIdScreen(),
        '/support': (context) => SupportScreen(),
        '/privacy': (context) => PrivacyScreen(),
        '/notifications': (context) => const NotificationSettingsScreen(),
      },
    );
  }
}
