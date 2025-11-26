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
        final adminFirstName = 'Admin';
        final adminLastName = 'User';
        // Middle name is optional, so we can leave it as null

        // Create auth user
        final credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Create admin user document with new UserModel structure
        final adminUser = UserModel(
          uid: credential.user!.uid,
          email: adminEmail,
          firstName: adminFirstName,
          middleName: null, // Optional - can be null
          lastName: adminLastName,
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
        print('👤 Name: ${adminUser.fullName}');
        print('🎯 Role: ${adminUser.role}');
      } else {
        print('ℹ️ Admin user already exists');

        // Optional: Print existing admin info
        final existingAdmin = UserModel.fromMap(adminQuery.docs.first.data());
        print('👤 Existing admin: ${existingAdmin.fullName}');
        print('📧 Email: ${existingAdmin.email}');
      }
    } catch (e) {
      print('❌ Error seeding admin: $e');

      // More detailed error information
      if (e is FirebaseAuthException) {
        print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
      }
    }
  }

  // Optional: Method to create multiple admin users with different roles
  static Future<void> seedMultipleAdmins() async {
    final admins = [
      {
        'email': 'superadmin@example.com',
        'password': 'superadmin123',
        'firstName': 'Super',
        'lastName': 'Admin',
        'role': 'super_admin',
      },
      {
        'email': 'manager@example.com',
        'password': 'manager123',
        'firstName': 'Manager',
        'lastName': 'User',
        'role': 'manager',
      },
    ];

    for (final adminData in admins) {
      try {
        // Check if admin already exists
        final adminQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: adminData['email'])
            .limit(1)
            .get();

        if (adminQuery.docs.isEmpty) {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminData['email']!,
            password: adminData['password']!,
          );

          final adminUser = UserModel(
            uid: credential.user!.uid,
            email: adminData['email']!,
            firstName: adminData['firstName']!,
            middleName: null,
            lastName: adminData['lastName']!,
            role: adminData['role']!,
            createdAt: DateTime.now(),
            isActive: true,
          );

          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(adminUser.toMap());

          print('✅ ${adminData['role']} user created: ${adminUser.fullName}');
        } else {
          print('ℹ️ ${adminData['role']} user already exists');
        }
      } catch (e) {
        print('❌ Error creating ${adminData['role']}: $e');
      }
    }
  }

  // Optional: Method to upgrade existing user to admin
  static Future<void> upgradeToAdmin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
      });
      print('✅ User $userId upgraded to admin');
    } catch (e) {
      print('❌ Error upgrading user to admin: $e');
    }
  }

  // Optional: Method to check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data()!);
        return userData.role == 'admin' || userData.role == 'super_admin';
      }
    }
    return false;
  }
}
