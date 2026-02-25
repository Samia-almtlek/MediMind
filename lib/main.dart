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
import 'presentation/screens/notification_settings_screen.dart';
import 'package:medimind/core/notification/notification_service.dart';
import 'data/local_db/drug_loader.dart';
import 'upload_products.dart';

/// Entry point for the app

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<String>('drugs');
  await DrugLoader.loadDrugsIfNeeded();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.openBox('medical_id_data');
  await Hive.openBox('medication_stock');
  await Hive.openBox('notification_settings');

  print('🗄️ Hive initialized successfully');
  await NotificationService.instance.init();

  // ⭐ EASIEST WAY: Trigger upload once (you can remove this after first run)
  //uploadProducts();

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
      home: const AuthGate(),
      routes: {
        '/signup': (context) => const RegisterScreen(),
        '/medications': (context) => const MedicationsScreen(),
        '/medical_id': (context) => const MedicalIdScreen(),
        '/support': (context) => const SupportScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/notifications': (context) => const NotificationSettingsScreen(),
      },
    );
  }
}
