import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

/// Generic Firestore service used as a reusable foundation.
///
/// This is intentionally generic and does not contain feature-specific logic.
/// Feature services can extend or compose this service later.
class FirestoreService extends FirebaseService {
  FirestoreService({FirebaseFirestore? firestoreInstance})
    : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  FirebaseFirestore get firestore => _firestore;

  /// Reads a single document from a collection.
  Future<Map<String, dynamic>?> getDocument({required String path}) async {
    try {
      final doc = await _firestore.doc(path).get();
      if (!doc.exists) return null;
      return doc.data();
    } on FirebaseException catch (exception, stack) {
      Error.throwWithStackTrace(
        FirebaseServiceException.fromFirebaseException(exception),
        stack,
      );
    }
  }

  /// Reads all documents from a collection.
  Future<List<Map<String, dynamic>>> getCollection({
    required String path,
  }) async {
    try {
      final snapshot = await _firestore.collection(path).get();
      return snapshot.docs
          .map((doc) => doc.data())
          .whereType<Map<String, dynamic>>()
          .toList();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  /// Reads records with canonical document IDs, independent of payload IDs.
  Future<List<Map<String, dynamic>>> getCollectionWithIds({
    required String path,
  }) async {
    final documents = await getCollectionSnapshots(path: path);
    return documents
        .map((doc) => {...?doc.data(), '_documentId': doc.id})
        .toList();
  }

  /// Reads documents with their IDs for models that support older schemas.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getCollectionSnapshots({
    required String path,
  }) async {
    try {
      final snapshot = await _firestore.collection(path).get();
      return snapshot.docs;
    } on FirebaseException catch (exception, stack) {
      Error.throwWithStackTrace(
        FirebaseServiceException.fromFirebaseException(exception),
        stack,
      );
    }
  }

  /// Adds a new document to a collection and returns the document ID.
  Future<String> addDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      final ref = await _firestore.collection(path).add(data);
      return ref.id;
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  /// Creates or overwrites a document.
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }

  /// Updates an existing document.
  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.doc(path).update(data);
    } on FirebaseException catch (exception, stack) {
      Error.throwWithStackTrace(
        FirebaseServiceException.fromFirebaseException(exception),
        stack,
      );
    }
  }

  /// Deletes a document.
  Future<void> deleteDocument({required String path}) async {
    try {
      await _firestore.doc(path).delete();
    } on FirebaseException catch (exception) {
      throw FirebaseServiceException.fromFirebaseException(exception);
    }
  }
}
