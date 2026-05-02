import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<bool> isUserRegistered(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> createUserProfile(String name, String email) async {
    final user = _auth.currentUser;
    if (user != null) {
      final trimmedEmail = email.trim();
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': trimmedEmail,
        'role': trimmedEmail.endsWith('.lb') ? 'staff' : 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'navigations': 0,
        'savedRooms': [],
      });
    }
  }
  Future<void> saveUserToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'emailVerified': true,
    }, SetOptions(merge: true)); // merge:true avoids overwriting if doc exists
  }

  bool isValidLauEmail(String email) {
    final emailLower = email.toLowerCase().trim();
    return emailLower.endsWith('@lau.edu.lb') || emailLower.endsWith('@lau.edu');
  }

  Future<AuthResult> signIn(String email, String password) async {
    final trimmedEmail = email.trim();
    if (!isValidLauEmail(trimmedEmail)) {
      return AuthResult.failure('Please use a valid @lau.edu.lb or @lau.edu email.');
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      // Removed the 'isUserRegistered' block from here.
      // We allow the sign-in so they can finish registration/verification.
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleFirebaseError(e));
    }
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    final trimmedEmail = email.trim();
    if (!isValidLauEmail(trimmedEmail)) {
      return AuthResult.failure('Only LAU email addresses (@lau.edu.lb or @lau.edu) are allowed.');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      await credential.user?.updateDisplayName(name);
      await credential.user?.sendEmailVerification();

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleFirebaseError(e));
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    if (!isValidLauEmail(trimmedEmail)) {
      return AuthResult.failure('Please enter a valid LAU email.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleFirebaseError(e));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> resendVerificationEmail() async {
    await currentUser?.sendEmailVerification();
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. If you haven\'t verified it, please Sign In to resume.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  AuthResult._({required this.success, this.user, this.error});
  factory AuthResult.success(User? user) => AuthResult._(success: true, user: user);
  factory AuthResult.failure(String error) => AuthResult._(success: false, error: error);
}
