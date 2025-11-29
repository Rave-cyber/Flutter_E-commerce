import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String user_id;
  final String firstname;
  final String middlename;
  final String lastname;
  final String address;
  final String contact;
  final DateTime? created_at;

  CustomerModel({
    required this.id,
    required this.user_id,
    required this.firstname,
    required this.middlename,
    required this.lastname,
    required this.address,
    required this.contact,
    this.created_at,
  });

  // Convert CustomerModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'address': address,
      'contact': contact,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
    };
  }

  // Create CustomerModel from Firestore Map
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      user_id: map['user_id'] ?? '',
      firstname: map['firstname'] ?? '',
      middlename: map['middlename'] ?? '',
      lastname: map['lastname'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
