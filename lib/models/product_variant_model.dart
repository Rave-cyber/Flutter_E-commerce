import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariantModel {
  String id;
  String product_id;
  String name;
  String image;
  List<String>? images;
  double base_price;
  double sale_price;
  int? stock;
  bool is_archived;
  DateTime created_at;
  DateTime updated_at;

  ProductVariantModel({
    required this.id,
    required this.product_id,
    required this.name,
    required this.image,
    this.images,
    required this.base_price,
    required this.sale_price,
    this.stock, // optional
    required this.is_archived,
    required this.created_at,
    required this.updated_at,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': product_id,
      'name': name,
      'image': image,
      'images': images,
      'base_price': base_price,
      'sale_price': sale_price,
      'stock': stock ?? 0, // default to 0
      'is_archived': is_archived,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: map['id'] ?? '',
      product_id: map['product_id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      base_price: (map['base_price'] ?? 0).toDouble(),
      sale_price: (map['sale_price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0, // default to 0
      is_archived: map['is_archived'] ?? false,
      created_at: (map['created_at'] as Timestamp).toDate(),
      updated_at: (map['updated_at'] as Timestamp).toDate(),
    );
  }
}
