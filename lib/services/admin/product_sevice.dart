import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '/models/product.dart';
import '/models/category_model.dart';
import '/models/brand_model.dart';

class PickedImage {
  final File file;
  final String url;

  PickedImage({required this.file, required this.url});
}

class ProductService {
  final CollectionReference _productCollection =
      FirebaseFirestore.instance.collection('products');

  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  final CollectionReference _brandCollection =
      FirebaseFirestore.instance.collection('brands');

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'drwoht0pd',
    'presets',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  /// Pick & upload image to Cloudinary
  Future<PickedImage?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return PickedImage(file: file, url: response.secureUrl);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  /// CREATE product
  Future<void> createProduct(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).set(product.toMap());
      print('Product created successfully!');
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// READ products (stream for UI)
  Stream<List<ProductModel>> getProducts() {
    return _productCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ProductModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).update(product.toMap());
      print('Product updated successfully!');
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// DELETE product
  Future<void> deleteProduct(String id) async {
    try {
      await _productCollection.doc(id).delete();
      print('Product deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// FETCH categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final snapshot = await _categoryCollection
          .where('is_archived', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) =>
              CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// FETCH brands
  Future<List<BrandModel>> fetchBrands() async {
    try {
      final snapshot =
          await _brandCollection.where('is_archived', isEqualTo: false).get();
      return snapshot.docs
          .map((doc) => BrandModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch brands: $e');
    }
  }

  /// TOGGLE archive / unarchive product
  Future<void> toggleArchive(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).update({
        'is_archived': !product.is_archived,
        'updated_at': DateTime.now(),
      });
      print(
          'Product "${product.name}" is now ${!product.is_archived ? 'active' : 'archived'}');
    } catch (e) {
      throw Exception('Failed to toggle archive status: $e');
    }
  }
}
