import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/category_model.dart';

class CategoryService {
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  /// CREATE category
  Future<void> createCategory(CategoryModel category) async {
    await _categoryCollection.doc(category.id).set(category.toMap());
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
    await _categoryCollection.doc(category.id).update(category.toMap());
  }

  /// DELETE category
  Future<void> deleteCategory(String id) async {
    await _categoryCollection.doc(id).delete();
  }

  /// 🔥 ARCHIVE / UNARCHIVE
  Future<void> toggleArchive(CategoryModel category) async {
    final updated = CategoryModel(
      id: category.id,
      name: category.name,
      is_archived: !category.is_archived,
      created_at: category.created_at,
      updated_at: DateTime.now(),
    );

    await updateCategory(updated);
  }
}
