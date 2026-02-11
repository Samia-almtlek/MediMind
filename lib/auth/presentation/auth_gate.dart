import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/auth_service.dart';
import '../../presentation/screens/main_screen.dart';
import '../presentation/screens/login_screen.dart';

/// AuthGate decides which screen to show
/// based on the authentication state.
///
/// This widget listens to Firebase authentication changes
/// and automatically redirects the user to:
/// - MainScreen if logged in
/// - LoginScreen if not authenticated
class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  // Instance of AuthService to keep Firebase logic outside UI
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to authentication state changes
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase checks auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          return MainScreen();
        }

        // If user is NOT logged in
        return LoginScreen();
      },
    );
  }
}
