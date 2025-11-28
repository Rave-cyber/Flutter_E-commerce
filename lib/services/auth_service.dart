import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';

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
    String password, {
    String? display_name,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        role: role,
        display_name: display_name,
        is_archived: false,
        created_at: DateTime.now(),
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
  // Get customer data
  // ------------------------------
  Future<CustomerModel?> getCustomerData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return CustomerModel.fromMap(querySnapshot.docs.first.data());
      }
    }
    return null;
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

  // ------------------------------
  // Sign out
  // ------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
