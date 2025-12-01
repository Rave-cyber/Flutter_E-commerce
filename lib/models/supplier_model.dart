import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String address;
  final String contact;
  final String contact_person;
  final bool is_archived;
  final DateTime? created_at;
  final DateTime? updated_at;

  SupplierModel({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.contact_person,
    required this.is_archived,
    this.created_at,
    this.updated_at,
  });

  // Convert SupplierModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact': contact,
      'contact_person': contact_person,
      'is_archived': is_archived,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → SupplierModel
  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      contact_person: map['contact_person'] ?? '',
      is_archived: map['is_archived'] ?? false,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
