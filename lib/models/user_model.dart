import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstname;
  final String middlename;
  final String lastname;
  final String role; // 'admin' or 'user'
  final DateTime? createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstname,
    required this.middlename,
    required this.lastname,
    required this.role,
    this.createdAt,
    required this.isActive,
  });

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'role': role,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'isActive': isActive,
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstname: map['firstname'] ?? '',
      middlename: map['middlename'] ?? '',
      lastname: map['lastname'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
