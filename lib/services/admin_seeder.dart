import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // STATIC method to seed the admin user
  static Future<void> seedAdmin() async {
    try {
      const adminEmail = 'admin@gmail.com';
      const adminPassword = '123456';

      User? user;
      bool isNewUser = false;

      try {
        // Try to create the user first
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        user = credential.user;
        isNewUser = true;
        print('✅ Admin Auth user created.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If email exists, try to sign in
          try {
            UserCredential credential = await _auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            user = credential.user;
            // print('✅ Admin verified via login.');
          } catch (signInError) {
            print(
                '⚠️ Admin email exists but login failed (wrong password?): $signInError');
            return;
          }
        } else {
          print('❌ Failed to create admin auth user: ${e.message}');
          return;
        }
      } catch (e) {
        print('❌ Unexpected error during admin creation: $e');
        return;
      }

      if (user != null) {
        // Ensure Firestore data exists and is correct
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists || isNewUser) {
          // Build the UserModel
          final adminUser = UserModel(
            id: user.uid,
            email: adminEmail,
            role: 'admin',
            display_name: 'System Administrator',
            created_at: DateTime.now(),
            is_archived: false,
          );

          await userDocRef.set(adminUser.toMap());
          print('✅ Admin Firestore document created/seeded.');
        } else {
          // Document exists, check if role is correct
          final data = userDoc.data();
          if (data != null && data['role'] != 'admin') {
            await userDocRef.update({'role': 'admin'});
            print('✅ Fixed admin role in Firestore.');
          }
        }
      }
    } catch (e) {
      print('❌ Error seeding admin: $e');
    }
  }
}
