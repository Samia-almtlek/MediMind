import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ==========================
  /// SIGN UP
  /// ==========================
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
        await user.updateDisplayName(fullName);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'profilePhotoUrl': '',
          'notificationsEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
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

  /// ==========================
  /// SIGN IN
  /// ==========================
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return credential;
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

/// ==========================
/// GOOGLE SIGN IN
/// ==========================
Future<UserCredential> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthException("Google sign-in was cancelled.");
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    final user = userCredential.user;

    if (user != null) {
      final userDoc =
          _firestore.collection('users').doc(user.uid);

      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'profilePhotoUrl': user.photoURL ?? '',
          'notificationsEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      } else {
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    }

    return userCredential;
  } catch (e) {
    throw AuthException("Google sign-in failed.");
  }
}

  /// ==========================
  /// RESEND VERIFICATION
  /// ==========================
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    }
  }

  /// ==========================
  /// PASSWORD RESET
  /// ==========================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      // Prevent revealing if account exists
    }
  }

  /// ==========================
  /// SIGN OUT
  /// ==========================
  Future<void> signOut() async {
  await _googleSignIn.signOut();
  await _auth.signOut();
}

  /// ==========================
  /// CURRENT USER
  /// ==========================
  User? get currentUser => _auth.currentUser;
}
