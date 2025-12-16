import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/attribute_model.dart';
import '/models/attribute_value_model.dart';

class AttributeService {
  final CollectionReference _attributeCollection =
      FirebaseFirestore.instance.collection('attributes');

  final CollectionReference _attributeValueCollection =
      FirebaseFirestore.instance.collection('attribute_values');

  /// =======================
  /// ATTRIBUTE METHODS
  /// =======================

  // Create new attribute
  Future<void> createAttribute(AttributeModel attribute) async {
    await _attributeCollection.doc(attribute.id).set(attribute.toMap());
  }

  // Update existing attribute
  Future<void> updateAttribute(AttributeModel attribute) async {
    await _attributeCollection.doc(attribute.id).update(attribute.toMap());
  }

  // Fetch all attributes (optionally filter archived)
  Future<List<AttributeModel>> getAttributes(
      {bool includeArchived = false}) async {
    QuerySnapshot snapshot;
    if (includeArchived) {
      snapshot = await _attributeCollection.get();
    } else {
      snapshot = await _attributeCollection
          .where('is_archived', isEqualTo: false)
          .get();
    }

    return snapshot.docs
        .map(
            (doc) => AttributeModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Fetch single attribute by ID
  Future<AttributeModel?> getAttributeById(String id) async {
    final doc = await _attributeCollection.doc(id).get();
    if (!doc.exists) return null;
    return AttributeModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// =======================
  /// ATTRIBUTE VALUE METHODS
  /// =======================

  // Create new attribute value
  Future<void> createAttributeValue(AttributeValueModel value) async {
    await _attributeValueCollection.doc(value.id).set(value.toMap());
  }

  // Update existing attribute value
  Future<void> updateAttributeValue(AttributeValueModel value) async {
    await _attributeValueCollection.doc(value.id).update(value.toMap());
  }

  // Fetch all values for a specific attribute
  Future<List<AttributeValueModel>> getAttributeValues(String attributeId,
      {bool includeArchived = false}) async {
    QuerySnapshot snapshot;
    if (includeArchived) {
      snapshot = await _attributeValueCollection
          .where('attribute_id', isEqualTo: attributeId)
          .get();
    } else {
      snapshot = await _attributeValueCollection
          .where('attribute_id', isEqualTo: attributeId)
          .where('is_archived', isEqualTo: false)
          .get();
    }

    return snapshot.docs
        .map((doc) =>
            AttributeValueModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Fetch single attribute value by ID
  Future<AttributeValueModel?> getAttributeValueById(String id) async {
    final doc = await _attributeValueCollection.doc(id).get();
    if (!doc.exists) return null;
    return AttributeValueModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Optional: delete methods (soft-delete via is_archived)
  Future<void> archiveAttribute(String id) async {
    await _attributeCollection.doc(id).update({'is_archived': true});
  }

  Future<void> unarchiveAttribute(String id) async {
    await _attributeCollection.doc(id).update({'is_archived': false});
  }

  Future<void> archiveAttributeValue(String id) async {
    await _attributeValueCollection.doc(id).update({'is_archived': true});
  }

  /// Stream of attributes (optionally include archived)
  Stream<List<AttributeModel>> getAttributesStream(
      {bool includeArchived = false}) {
    Query query = _attributeCollection;
    if (!includeArchived) {
      query = query.where('is_archived', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              AttributeModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
