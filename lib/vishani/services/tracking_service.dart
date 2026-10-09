import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/driver_tracking_model.dart';

class TrackingService {
  final FirebaseFirestore? _firestore;

  TrackingService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _instance {
    if (_firestore != null) return _firestore;
    return FirebaseFirestore.instance;
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Streams real-time driver coordinates and status
  /// If Firebase is not configured, provides a smooth real-time stream simulation
  Stream<DriverTrackingModel> streamDriverLocation(String driverId) {
    if (!_isFirebaseAvailable) {
      return _generateSimulatedDriverStream();
    }

    try {
      return _instance
          .collection('driver_trips')
          .doc(driverId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return DriverTrackingModel.fromFirestore(doc);
        }
        return _fallbackDriver;
      }).handleError((_) => _fallbackDriver);
    } catch (_) {
      return _generateSimulatedDriverStream();
    }
  }

  /// Fetches the "Next Collection" card data for the resident dashboard
  Future<Map<String, dynamic>> fetchNextCollection(String userId) async {
    if (!_isFirebaseAvailable) {
      return {
        'date': DateTime.now().add(const Duration(days: 1)),
        'category': 'Recyclable (Paper & Plastics)',
        'timeWindow': '08:00 AM - 10:00 AM',
        'zone': 'Colombo Municipal Zone 3',
        'status': 'Scheduled',
      };
    }

    try {
      final doc = await _instance.collection('collection_schedules').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (_) {}

    return {
      'date': DateTime.now().add(const Duration(days: 1)),
      'category': 'Recyclable (Paper & Plastics)',
      'timeWindow': '08:00 AM - 10:00 AM',
      'zone': 'Colombo Municipal Zone 3',
      'status': 'Scheduled',
    };
  }

  static final DriverTrackingModel _fallbackDriver = DriverTrackingModel(
    driverId: 'DRV-001',
    driverName: 'Nalin Perera',
    driverPhone: '+94771234567',
    currentLatitude: 6.9271,
    currentLongitude: 79.8612,
    destinationLatitude: 6.9319,
    destinationLongitude: 79.8578,
    etaMinutes: 25,
    vehicleNumber: 'WP-NA-4521',
    status: 'In Progress',
  );

  /// Smoothly interpolates truck position for live testing
  Stream<DriverTrackingModel> _generateSimulatedDriverStream() {
    return Stream.periodic(const Duration(seconds: 4), (tick) {
      final factor = (tick % 20) / 20.0;
      final startLat = 6.9200;
      final startLng = 79.8650;
      final endLat = 6.9319;
      final endLng = 79.8578;

      final currentLat = startLat + (endLat - startLat) * factor;
      final currentLng = startLng + (endLng - startLng) * factor;
      final remainingEta = (25 * (1.0 - factor)).round().clamp(1, 25);

      return DriverTrackingModel(
        driverId: 'DRV-001',
        driverName: 'Nalin Perera',
        driverPhone: '+94771234567',
        currentLatitude: currentLat,
        currentLongitude: currentLng,
        destinationLatitude: endLat,
        destinationLongitude: endLng,
        etaMinutes: remainingEta,
        vehicleNumber: 'WP-NA-4521',
        status: remainingEta <= 3 ? 'Arriving Soon' : 'In Progress',
      );
    });
  }
}
