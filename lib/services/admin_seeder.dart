import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // STATIC method to seed the admin user
  static Future<void> seedAdmin() async {
    try {
      // Check if an admin already exists in Firestore
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        print('ℹ️ Admin user already exists.');
        return;
      }

      // Admin credentials
      const adminEmail = 'admin@gmail.com';
      const adminPassword = '123456';

      // Check if email already exists in Firebase Auth (optional safety)
      final existingMethods =
          await _auth.fetchSignInMethodsForEmail(adminEmail);

      UserCredential credential;

      if (existingMethods.isEmpty) {
        // Create Firebase Auth user
        credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } else {
        // Email already exists — retrieve existing user instead of failing
        final existingUser = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        credential = existingUser;
      }

      // Build the UserModel for Firestore
      final adminUser = UserModel(
        id: credential.user!.uid,
        email: adminEmail,
        role: 'admin',
        display_name: 'System Administrator', // valid for admin-only
        created_at: DateTime.now(),
        is_archived: false,
      );

      // Save admin data to Firestore
      await _firestore
          .collection('users')
          .doc(adminUser.id)
          .set(adminUser.toMap());

      print('✅ Admin user created/verified successfully.');
      print('📧 Email: $adminEmail');
      print('🔑 Password: $adminPassword (not stored in Firestore)');
    } catch (e) {
      print('❌ Error seeding admin: $e');
    }
  }
}
