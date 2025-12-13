import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class SuperAdminSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // STATIC method to seed the super admin user
  static Future<void> seedSuperAdmin() async {
    try {
      // USING A NEW EMAIL to avoid 'invalid-credential' from previous conflicts
      const superAdminEmail = 'superadmin1@gmail.com';
      const superAdminPassword = '123456';

      User? user;
      bool isNewUser = false;

      print('🔄 Attempting to seed Super Admin: $superAdminEmail');

      try {
        // 1. Try to create the user
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: superAdminEmail,
          password: superAdminPassword,
        );
        user = credential.user;
        isNewUser = true;
        print('✅ Super admin Auth user CREATED successfully.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('ℹ️ Email already exists. Trying to login...');
          // 2. If email exists, try to sign in to verify we have access
          try {
            UserCredential credential = await _auth.signInWithEmailAndPassword(
              email: superAdminEmail,
              password: superAdminPassword,
            );
            user = credential.user;
            print('✅ Super admin verified via login.');
          } catch (signInError) {
            print(
                '❌ CRITICAL: Super admin email exists but password verification failed.');
            print('❌ Error: $signInError');
            print(
                '👉 ACTION REQUIRED: Manually delete user $superAdminEmail from Firebase Console Authentication or use a different email in Seeder.');
            return;
          }
        } else {
          print('❌ Failed to create super admin auth user: ${e.message}');
          return;
        }
      } catch (e) {
        print('❌ Unexpected error during super admin creation: $e');
        return;
      }

      if (user != null) {
        // 3. Ensure Firestore data exists and is correct
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists || isNewUser) {
          // Build the UserModel
          final superAdminUser = UserModel(
            id: user.uid,
            email: superAdminEmail,
            role: 'super_admin', // super admin role
            display_name: 'Super Administrator',
            created_at: DateTime.now(),
            is_archived: false,
          );

          await userDocRef.set(superAdminUser.toMap());
          print('✅ Super admin Firestore document created/seeded.');
        } else {
          // Document exists, check if role is correct
          final data = userDoc.data();
          if (data != null && data['role'] != 'super_admin') {
            await userDocRef.update({'role': 'super_admin'});
            print('✅ Fixed super admin role in Firestore.');
          }
        }

        print('------------------------------------------------');
        print('🔑 SUPER ADMIN CREDENTIALS:');
        print('📧 Email:    $superAdminEmail');
        print('🔑 Password: $superAdminPassword');
        print('------------------------------------------------');
      }
    } catch (e) {
      print('❌ Error seeding super admin: $e');
    }
  }
}
