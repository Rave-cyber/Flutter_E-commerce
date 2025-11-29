import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/views/home/home_screen.dart';
import 'models/product_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get featured products
  static Stream<List<Product>> getFeaturedProducts() {
    return _firestore
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get products by category
  static Stream<List<Product>> getProductsByCategory(String category) {
    if (category == 'All') {
      return _firestore.collection('products').snapshots().map((snapshot) =>
          snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList());
    }

    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get product by ID
  static Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (doc.exists) {
      return Product.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Add new product (for admin)
  static Future<void> addProduct(Product product) {
    return _firestore.collection('products').add(product.toMap());
  }

  Stream<List<ProductModel>>? getProducts() {}
}

class ProductModel {
  String? get id => null;

  Object? toMap() {}

  static fromMap(Map<String, dynamic> data) {}
}
