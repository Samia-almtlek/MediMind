import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

/// Service responsible for handling all authentication logic.
/// This class isolates Firebase from the UI layer.
class AuthService {
  // Create a single instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream that listens to authentication state changes.
  /// This allows the app to react automatically when a user logs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up using email & password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        // ✅ Update display name in Firebase Auth
        await user.updateDisplayName(fullName);

        // ✅ Save user in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException("An account already exists with this email.");

        case 'invalid-email':
          throw AuthException("Invalid email address.");

        case 'weak-password':
          throw AuthException("Password is too weak.");

        default:
          throw AuthException("Registration failed. Please try again.");
      }
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
  switch (e.code) {
    case 'invalid-email':
      throw AuthException("Invalid email address.");

    case 'user-disabled':
      throw AuthException("This account has been disabled.");

    case 'wrong-password':
    case 'user-not-found':
      throw AuthException("Invalid email or password.");

    case 'too-many-requests':
      throw AuthException("Too many attempts. Please try again later.");

    default:
      throw AuthException("Login failed. Please try again.");
  }
}

  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      //  Do nothing to avoid revealing account existence
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current logged-in user
  User? get currentUser => _auth.currentUser;
}
