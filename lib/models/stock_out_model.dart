import 'package:cloud_firestore/cloud_firestore.dart';

class StockOutModel {
  final String id;
  final String? product_id;
  final String? product_variant_id;
  final int quantity;
  final String reason;
  final DateTime? created_at;
  final DateTime? updated_at;

  StockOutModel({
    required this.id,
    this.product_id,
    this.product_variant_id,
    required this.quantity,
    required this.reason,
    this.created_at,
    this.updated_at,
  });

  // Convert StockOutModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': product_id,
      'product_variant_id': product_variant_id,
      'quantity': quantity,
      'reason': reason,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → StockOutModel
  factory StockOutModel.fromMap(Map<String, dynamic> map) {
    return StockOutModel(
      id: map['id'] ?? '',
      product_id: map['product_id'],
      product_variant_id: map['product_variant_id'],
      quantity: map['quantity'] ?? 0,
      reason: map['reason'] ?? '',
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
