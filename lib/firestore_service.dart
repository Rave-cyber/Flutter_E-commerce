import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product.dart'; // Import the correct model

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get featured products
  static Stream<List<ProductModel>> getFeaturedProducts() {
    return _firestore
        .collection('products')
        .where('is_featured', isEqualTo: true) // Note: changed to is_featured
        .snapshots()
        .map((snapshot) {
      print('Featured products snapshot: ${snapshot.docs.length} documents');
      return snapshot.docs.map((doc) {
        print('Featured product data: ${doc.data()}');
        return ProductModel.fromMap(doc.data());
      }).toList();
    }).handleError((error) {
      print('Error fetching featured products: $error');
      throw error;
    });
  }

  // Get products by category
  static Stream<List<ProductModel>> getProductsByCategory(String category) {
    print('Fetching products for category: $category');

    if (category == 'All') {
      return _firestore.collection('products').snapshots().map((snapshot) {
        print('All products snapshot: ${snapshot.docs.length} documents');
        snapshot.docs.forEach((doc) {
          print('Product data: ${doc.data()}');
        });
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();
      }).handleError((error) {
        print('Error fetching all products: $error');
        throw error;
      });
    }

    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      print('Category products snapshot: ${snapshot.docs.length} documents');
      snapshot.docs.forEach((doc) {
        print('Category product data: ${doc.data()}');
      });
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    }).handleError((error) {
      print('Error fetching category products: $error');
      throw error;
    });
  }

  // Get product by ID
  static Future<ProductModel?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Add new product (for admin)
  static Future<void> addProduct(ProductModel product) {
    return _firestore.collection('products').add(product.toMap());
  }
}
