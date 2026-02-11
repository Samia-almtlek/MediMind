import 'package:firebase_auth/firebase_auth.dart';

/// Service responsible for handling all authentication logic.
/// This class isolates Firebase from the UI layer.
class AuthService {
  // Create a single instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that listens to authentication state changes.
  /// This allows the app to react automatically when a user logs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up using email & password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Sign in using email & password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current logged-in user
  User? get currentUser => _auth.currentUser;
}
