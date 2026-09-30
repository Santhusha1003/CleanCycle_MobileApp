import 'package:cloud_firestore/cloud_firestore.dart';

/// Common base contract for CleanCycle models.
///
/// This is intentionally lightweight and generic.
/// It keeps Firestore compatibility simple without introducing a large framework.
///
/// Each feature-specific model can extend this contract and implement its own
/// conversion logic as needed.
abstract class BaseModel {
  /// Converts the model to a Firestore-compatible map.
  Map<String, dynamic> toMap();

  /// Creates a model instance from a Firestore map.
  factory BaseModel.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('Subclasses must implement fromMap().');
  }

  /// Creates a model instance from a Firestore document snapshot.
  factory BaseModel.fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return BaseModel.fromMap(data);
  }
}

/// Utility helper for common value conversion in Firestore-backed models.
///
/// This provides a simple, reusable conversion layer for standard Dart values.
/// It avoids repeating conversion code across feature models.
class ModelValueConverter {
  ModelValueConverter._();

  /// Converts Firestore values to consistent Dart types.
  static dynamic fromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return value;
  }

  /// Converts Dart values to Firestore-compatible values.
  static dynamic toValue(dynamic value) {
    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return value;
  }
}

/// Helper for safe map extraction.
class ModelMapHelper {
  ModelMapHelper._();

  /// Returns a value from a map or the provided default.
  static T value<T>(Map<String, dynamic> map, String key, T defaultValue) {
    final value = map[key];
    if (value == null) {
      return defaultValue;
    }
    return value as T;
  }

  /// Returns a value from a map or null safely.
  static T? nullableValue<T>(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    return value as T;
  }
}
