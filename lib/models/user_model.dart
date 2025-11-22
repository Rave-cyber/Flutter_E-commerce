import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final DateTime? createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    required this.isActive,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.now(), // Convert DateTime to Timestamp
      'isActive': isActive,
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
