import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariantAttributeModel {
  String id;
  String product_variant_id;
  String attribute_id;
  String attribute_value_id;
  DateTime created_at;
  DateTime updated_at;

  ProductVariantAttributeModel({
    required this.id,
    required this.product_variant_id,
    required this.attribute_id,
    required this.attribute_value_id,
    required this.created_at,
    required this.updated_at,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_variant_id': product_variant_id,
      'attribute_id': attribute_id,
      'attribute_value_id': attribute_value_id,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  factory ProductVariantAttributeModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantAttributeModel(
      id: map['id'],
      product_variant_id: map['product_variant_id'],
      attribute_id: map['attribute_id'],
      attribute_value_id: map['attribute_value_id'],
      created_at: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updated_at: map['updated_at'] != null
          ? (map['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
