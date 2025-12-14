import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public getter for Firestore
  FirebaseFirestore get firestore => _firestore;

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

  // ------------------------------
  // Sign in with Google
  // ------------------------------
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      } else {
        // Create new user with default role 'customer'
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: 'customer',
          display_name: userCredential.user!.displayName,
          is_archived: false,
          created_at: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        // Create customer profile
        final nameParts =
            userCredential.user!.displayName?.split(' ') ?? ['', '', ''];
        final customer = CustomerModel(
          id: '', // Will be set by Firestore
          user_id: userCredential.user!.uid,
          firstname: nameParts.length > 0 ? nameParts[0] : '',
          middlename: nameParts.length > 2 ? nameParts[1] : '',
          lastname: nameParts.length > 1 ? nameParts.last : '',
          address: '',
          contact: userCredential.user!.email!,
          created_at: DateTime.now(),
        );

        await _firestore.collection('customers').add(customer.toMap());

        return newUser;
      }
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }
}
