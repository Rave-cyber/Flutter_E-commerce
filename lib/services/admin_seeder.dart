import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Make this a STATIC method
  static Future<void> seedAdmin() async {
    try {
      // Check if admin already exists
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        // Create admin user
        final adminEmail = 'admin@example.com';
        final adminPassword = 'admin123';
        final adminName = 'Administrator';

        // Create auth user
        final credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Create admin user document
        final adminUser = UserModel(
          uid: credential.user!.uid,
          email: adminEmail,
          name: adminName,
          role: 'admin',
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(adminUser.toMap());

        print('✅ Admin user created successfully');
        print('📧 Email: $adminEmail');
        print('🔑 Password: $adminPassword');
      } else {
        print('ℹ️ Admin user already exists');
      }
    } catch (e) {
      print('❌ Error seeding admin: $e');
    }
  }
}
