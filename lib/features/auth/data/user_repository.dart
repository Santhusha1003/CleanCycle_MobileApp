import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/utils/error_mapper.dart';
import '../models/app_user.dart';

/// CRUD for the `users/{uid}` Firestore collection.
///
/// Security rules (see `firestore.rules`) already block role changes; this
/// class also never writes `role` on update so a buggy client cannot try.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _dbOverride = firestore;

  final FirebaseFirestore? _dbOverride;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _users.doc(uid);

  /// CREATE: new resident profile after Firebase Auth registration.
  Future<void> createResidentProfile({
    required User authUser,
    required String name,
    required String phone,
    required String addressZone,
    String requestedRole = AppRoles.resident,
    String? fcmToken,
  }) async {
    if (!AppRoles.isValid(requestedRole)) {
      throw ArgumentError.value(requestedRole, 'requestedRole');
    }
    final profile = AppUser(
      uid: authUser.uid,
      name: name.trim(),
      email: authUser.email ?? '',
      phone: phone.trim(),
      role: AppRoles.resident, // never taken from the UI
      // Approval must come from a trusted backend/admin. Rules still forbid
      // self-promotion; requestedRole grants no privileged access.
      requestedRole: requestedRole,
      addressZone: addressZone.trim(),
      emailVerified: false,
      createdAt: DateTime.now(),
      fcmToken: fcmToken,
    );
    await _doc(authUser.uid).set(profile.toCreateMap());
  }

  /// CREATE (Google first-time): fill gaps from the Auth user only.
  Future<void> ensureResidentProfile(User authUser, {String? fcmToken}) async {
    final existing = await _doc(authUser.uid).get();
    if (existing.exists) return;
    final profile = AppUser(
      uid: authUser.uid,
      name: authUser.displayName ?? 'Resident',
      email: authUser.email ?? '',
      phone: authUser.phoneNumber ?? '',
      role: AppRoles.resident,
      requestedRole: AppRoles.resident,
      addressZone: '',
      emailVerified: authUser.emailVerified,
      createdAt: DateTime.now(),
      fcmToken: fcmToken,
    );
    await _doc(authUser.uid).set(profile.toCreateMap());
  }

  /// READ: single profile, or null if the document is missing.
  Future<AppUser?> getById(String uid) async {
    final snap = await _doc(uid).get();
    // TEMPORARY runtime diagnostics; never log credentials or tokens.
    if (kDebugMode) {
      debugPrint(
        '[AUTH DEBUG] Profile path: users/$uid; exists: ${snap.exists}; '
        'fromCache: ${snap.metadata.isFromCache}; '
        'Firestore role: ${snap.data()?['role']}; '
        'requestedRole: ${snap.data()?['requestedRole']}',
      );
    }
    if (!snap.exists) return null;
    final user = AppUser.fromFirestore(snap);
    if (kDebugMode) {
      debugPrint('[AUTH DEBUG] AppUser role: "${user.role}"');
    }
    return user;
  }

  /// READ (live): used by Account Settings so edits appear immediately.
  Stream<AppUser?> watchById(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  /// UPDATE: last successful login timestamp.
  Future<void> updateLastLogin(String uid) {
    return _doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  /// UPDATE: mirror Firebase Auth's emailVerified flag.
  Future<void> updateEmailVerified(String uid, {required bool verified}) {
    return _doc(uid).update({'emailVerified': verified});
  }

  Future<void> saveEmailOtp({
    required String uid,
    required String hash,
    required DateTime expiresAt,
  }) {
    return _doc(uid).update({
      'emailOtpHash': hash,
      'emailOtpExpiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  Future<({String hash, DateTime expiresAt})?> getEmailOtp(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    final hash = data['emailOtpHash'] as String?;
    final expires = data['emailOtpExpiresAt'];
    if (hash == null || expires is! Timestamp) return null;
    return (hash: hash, expiresAt: expires.toDate());
  }

  Future<void> markEmailOtpVerified(String uid) {
    return _doc(uid).update({
      'emailVerified': true,
      'emailOtpHash': FieldValue.delete(),
      'emailOtpExpiresAt': FieldValue.delete(),
    });
  }

  /// UPDATE: profile fields the user is allowed to change.
  Future<void> updateProfile(
    String uid, {
    String? name,
    String? phone,
    String? addressZone,
    String? language,
    String? avatarUrl,
  }) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (addressZone != null) data['addressZone'] = addressZone.trim();
    if (language != null) data['language'] = language;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isEmpty) return Future.value();
    return _doc(uid).update(data);
  }

  /// UPDATE: notification preference toggles.
  Future<void> updateNotificationPrefs(String uid, NotificationPrefs prefs) {
    return _doc(uid).update({'notificationPrefs': prefs.toMap()});
  }

  /// UPDATE: FCM device token (refreshed on each login / token rotation).
  Future<void> saveFcmToken(String uid, String token) {
    return _doc(uid).update({'fcmToken': token});
  }

  /// UPDATE: clear token on logout so this device stops receiving user pushes.
  Future<void> clearFcmToken(String uid) {
    return _doc(uid).update({'fcmToken': FieldValue.delete()});
  }

  /// DELETE: remove the Firestore document (Auth user is deleted separately).
  Future<void> deleteProfile(String uid) {
    return _doc(uid).delete();
  }

  /// Throws [RoleMismatchException] if the stored role is not [expectedRole].
  /// Optional guard for callers that explicitly require a particular role.
  Future<AppUser> requireRole(String uid, String expectedRole) async {
    final user = await getById(uid);
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Your profile could not be found. Please register first.',
      );
    }
    if (user.role != expectedRole) {
      throw RoleMismatchException(expectedRole, user.role);
    }
    return user;
  }
}
