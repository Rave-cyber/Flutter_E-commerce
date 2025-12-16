import 'package:cloud_firestore/cloud_firestore.dart';

class StockInOutModel {
  final String id;
  final String stock_in_id;
  final String stock_out_id;
  final int deducted_quantity;
  final DateTime? created_at;
  final DateTime? updated_at;

  StockInOutModel({
    required this.id,
    required this.stock_in_id,
    required this.stock_out_id,
    required this.deducted_quantity,
    this.created_at,
    this.updated_at,
  });

  // Convert StockInOutModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'stock_in_id': stock_in_id,
      'stock_out_id': stock_out_id,
      'deducted_quantity': deducted_quantity,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → StockInOutModel
  factory StockInOutModel.fromMap(Map<String, dynamic> map) {
    return StockInOutModel(
      id: map['id'] ?? '',
      stock_in_id: map['stock_in_id'] ?? '',
      stock_out_id: map['stock_out_id'] ?? '',
      deducted_quantity: map['deducted_quantity'] ?? 0,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
