import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Make this a STATIC method
  static Future<void> seedAdmin() async {
    try {
      // Check if an admin already exists
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        // Admin account details
        const adminEmail = 'admin@example.com';
        const adminPassword = 'admin123';

        // Split name into your new format
        const firstname = 'System';
        const middlename = '';
        const lastname = 'Administrator';

        // Create auth user
        final credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Create admin user document
        final adminUser = UserModel(
          uid: credential.user!.uid,
          email: adminEmail,
          firstname: firstname,
          middlename: middlename,
          lastname: lastname,
          role: 'admin',
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Save to Firestore
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
