import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String role; // 'admin' or 'user'
  final String? display_name; // optional
  final DateTime? created_at;
  final bool is_archived;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.display_name,
    this.created_at,
    required this.is_archived,
  });

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      if (display_name != null) 'display_name': display_name,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'is_archived': is_archived,
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      display_name: map['display_name'],
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      is_archived: map['is_archived'] ?? false,
    );
  }
}
