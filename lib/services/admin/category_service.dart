import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/category_model.dart';

class CategoryService {
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  /// CREATE category
  Future<void> createCategory(CategoryModel category) async {
    try {
      await _categoryCollection.doc(category.id).set(category.toMap());
      print('Category created successfully!');
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// READ categories (stream for UI)
  Stream<List<CategoryModel>> getCategories() {
    return _categoryCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoryCollection.doc(category.id).update(category.toMap());
      print('Category updated successfully!');
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// DELETE category
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryCollection.doc(id).delete();
      print('Category deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
