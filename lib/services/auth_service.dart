import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error in signInWithGoogle: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
      throw e;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get sign-in methods for email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await _auth.fetchSignInMethodsForEmail(email);
  }

  // Update user password (requires reauthentication)
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("User not authenticated or missing email");
    }

    try {
      // Re-authenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Then update password
      await user.updatePassword(newPassword);
    } catch (e) {
      print("Error updating password: $e");
      throw e;
    }
  }

  // Update user display name
  Future<void> updateUserDisplayName(String name) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    try {
      await user.updateDisplayName(name);

      // Also update in Firestore
      if (currentUserId != null) {
        await _firestore.collection('users').doc(currentUserId).update({
          'name': name
        });
      }
    } catch (e) {
      print("Error updating user display name: $e");
      throw e;
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print("Error getting user profile: $e");
    }
    return null;
  }
}