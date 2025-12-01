import 'package:cloud_firestore/cloud_firestore.dart';

class StockCheckerModel {
  final String id;
  final String firstname;
  final String middlename;
  final String lastname;
  final String address;
  final String contact;
  final bool is_archived;
  final DateTime? created_at;
  final DateTime? updated_at;

  StockCheckerModel({
    required this.id,
    required this.firstname,
    required this.middlename,
    required this.lastname,
    required this.address,
    required this.contact,
    required this.is_archived,
    this.created_at,
    this.updated_at,
  });

  // Convert StockCheckerModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'address': address,
      'contact': contact,
      'is_archived': is_archived,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → StockCheckerModel
  factory StockCheckerModel.fromMap(Map<String, dynamic> map) {
    return StockCheckerModel(
      id: map['id'] ?? '',
      firstname: map['firstname'] ?? '',
      middlename: map['middlename'] ?? '',
      lastname: map['lastname'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      is_archived: map['is_archived'] ?? false,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
