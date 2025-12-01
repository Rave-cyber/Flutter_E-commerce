import 'package:cloud_firestore/cloud_firestore.dart';

class StockInModel {
  final String id;
  final String? product_id; // nullable
  final String? product_variant_id; // nullable
  final String supplier_id;
  final String warehouse_id;
  final String stock_checker_id;
  final int quantity;
  final int remaining_quantity;
  final double price;
  final String reason;
  final bool is_archived;
  final DateTime? created_at;
  final DateTime? updated_at;

  StockInModel({
    required this.id,
    this.product_id,
    this.product_variant_id,
    required this.supplier_id,
    required this.warehouse_id,
    required this.stock_checker_id,
    required this.quantity,
    required this.remaining_quantity,
    required this.price,
    required this.reason,
    required this.is_archived,
    this.created_at,
    this.updated_at,
  });

  // Convert StockInModel → Map for Firestore
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': product_id,
      'product_variant_id': product_variant_id,
      'supplier_id': supplier_id,
      'warehouse_id': warehouse_id,
      'stock_checker_id': stock_checker_id,
      'quantity': quantity,
      'remaining_quantity': remaining_quantity,
      'price': price,
      'reason': reason,
      'is_archived': is_archived,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  // Convert Firestore Map → StockInModel
  factory StockInModel.fromMap(Map<String, dynamic> map) {
    return StockInModel(
      id: map['id'] ?? '',
      product_id: map['product_id'],
      product_variant_id: map['product_variant_id'],
      supplier_id: map['supplier_id'] ?? '',
      warehouse_id: map['warehouse_id'] ?? '',
      stock_checker_id: map['stock_checker_id'] ?? '',
      quantity: map['quantity'] ?? 0,
      remaining_quantity: map['remaining_quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      is_archived: map['is_archived'] ?? false,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
