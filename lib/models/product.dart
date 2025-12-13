import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String brand_id;
  final String category_id;
  final String name;
  final String description;
  final String image;
  final double base_price;
  final double sale_price;
  final int? stock_quantity;
  final bool is_archived;
  final bool is_featured;
  final DateTime? created_at;
  final DateTime? updated_at;

  ProductModel({
    required this.id,
    required this.brand_id,
    required this.category_id,
    required this.name,
    required this.description,
    required this.image,
    required this.base_price,
    required this.sale_price,
    this.stock_quantity, // optional
    required this.is_archived,
    this.is_featured = false,
    this.created_at,
    this.updated_at,
  });

  int get totalStock => stock_quantity ?? 0;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'brand_id': brand_id,
      'category_id': category_id,
      'name': name,
      'description': description,
      'image': image,
      'base_price': base_price,
      'sale_price': sale_price,
      'stock_quantity': stock_quantity ?? 0,
      'is_archived': is_archived,
      'is_featured': is_featured,
      'created_at': created_at != null
          ? Timestamp.fromDate(created_at!)
          : Timestamp.now(),
      'updated_at': updated_at != null
          ? Timestamp.fromDate(updated_at!)
          : Timestamp.now(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      brand_id: map['brand_id'] ?? '',
      category_id: map['category_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      base_price: map['base_price'] != null
          ? (map['base_price'] as num).toDouble()
          : 0.0,
      sale_price: map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : 0.0,
      stock_quantity: map['stock_quantity'] != null
          ? map['stock_quantity'] as int
          : 0, // default to 0
      is_archived: map['is_archived'] ?? false,
      is_featured: map['is_featured'] ?? false,
      created_at: (map['created_at'] as Timestamp?)?.toDate(),
      updated_at: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
