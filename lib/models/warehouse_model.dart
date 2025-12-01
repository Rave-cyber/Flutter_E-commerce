import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseModel {
  final String id;
  final String name;
  final bool is_archived;
  final DateTime? created_at;
  final DateTime? updated_at;

  WarehouseModel({
    required this.id,
    required this.name,
    required this.is_archived,
    this.created_at,
    this.updated_at,
  });

  // Convert WarehouseModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'is_archived': is_archived,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → WarehouseModel
  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      is_archived: map['is_archived'] ?? false,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
