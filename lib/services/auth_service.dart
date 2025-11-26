import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ------------------------------
  // Sign in
  // ------------------------------
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // ------------------------------
  // Register user
  // ------------------------------
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String firstname,
    String middlename,
    String lastname,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        firstname: firstname,
        middlename: middlename,
        lastname: lastname,
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // ------------------------------
  // Sign out
  // ------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ------------------------------
  // Get current user profile
  // ------------------------------
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
    }
    return null;
  }
}
