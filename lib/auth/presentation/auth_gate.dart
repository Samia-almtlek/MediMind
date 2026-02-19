import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medimind/presentation/screens/main_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../service/auth_service.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/login_screen.dart';

/// AuthGate decides which screen to show
/// based on the authentication state.
///
/// This widget listens to Firebase authentication changes
/// and automatically redirects the user to:
/// - MainScreen if logged in
/// - LoginScreen if not authenticated
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Instance of AuthService to keep Firebase logic outside UI
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkGDPR();
  }

  void _checkGDPR() {
    final box = Hive.box('medical_id_data');
    final accepted = box.get('gdpr_accepted', defaultValue: false) as bool;

    if (!accepted) {
      Future.delayed(Duration.zero, _showGDPRBottomSheet);
    }
  }

  void _showGDPRBottomSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Privacy Policy",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "MediMind stores your medical data securely on your device anduses local encryption. By continuing, you confirm that you have read and agree to our data processing terms.",
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Hive.box('medical_id_data').put('gdpr_accepted', true);
                Navigator.pop(context);
              },
              child: const Text("I Accept"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to authentication state changes
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase checks auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          if (user.emailVerified) {
            return MainScreen();
          } else {
            return const LoginScreen();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
