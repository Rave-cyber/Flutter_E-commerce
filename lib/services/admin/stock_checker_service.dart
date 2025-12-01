import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/stock_checker_model.dart';

class StockCheckerService {
  final CollectionReference _stockCheckerCollection =
      FirebaseFirestore.instance.collection('stock_checkers');

  /// CREATE stock checker
  Future<void> createStockChecker(StockCheckerModel checker) async {
    await _stockCheckerCollection.doc(checker.id).set(checker.toMap());
  }

  /// READ stock checkers (live stream)
  Stream<List<StockCheckerModel>> getStockCheckers() {
    return _stockCheckerCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                StockCheckerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE stock checker
  Future<void> updateStockChecker(StockCheckerModel checker) async {
    await _stockCheckerCollection.doc(checker.id).update(checker.toMap());
  }

  /// DELETE stock checker
  Future<void> deleteStockChecker(String id) async {
    await _stockCheckerCollection.doc(id).delete();
  }

  /// ARCHIVE / UNARCHIVE stock checker
  Future<void> toggleArchive(StockCheckerModel checker) async {
    final updated = StockCheckerModel(
      id: checker.id,
      firstname: checker.firstname,
      middlename: checker.middlename,
      lastname: checker.lastname,
      address: checker.address,
      contact: checker.contact,
      is_archived: !checker.is_archived,
      created_at: checker.created_at,
      updated_at: DateTime.now(),
    );

    await updateStockChecker(updated);
  }

  Future<List<StockCheckerModel>> fetchStockCheckersOnce() async {
    final snapshot = await _stockCheckerCollection
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            StockCheckerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
