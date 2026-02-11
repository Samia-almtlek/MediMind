import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

Future<void> resendVerificationEmail() async {
  final user = _auth.currentUser;

  if (user != null && !user.emailVerified) {
    await user.sendEmailVerification();
  }
}

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current logged-in user
  User? get currentUser => _auth.currentUser;
}
