import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_roles.dart';

/// Toggles stored at `users/{uid}.notificationPrefs`.
class NotificationPrefs {
  const NotificationPrefs({
    this.collectionReminders = true,
    this.specialPickupUpdates = true,
    this.serviceUpdates = true,
  });

  final bool collectionReminders;
  final bool specialPickupUpdates;
  final bool serviceUpdates;

  factory NotificationPrefs.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPrefs();
    return NotificationPrefs(
      collectionReminders: map['collectionReminders'] as bool? ?? true,
      specialPickupUpdates: map['specialPickupUpdates'] as bool? ?? true,
      serviceUpdates: map['serviceUpdates'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'collectionReminders': collectionReminders,
        'specialPickupUpdates': specialPickupUpdates,
        'serviceUpdates': serviceUpdates,
      };

  NotificationPrefs copyWith({
    bool? collectionReminders,
    bool? specialPickupUpdates,
    bool? serviceUpdates,
  }) {
    return NotificationPrefs(
      collectionReminders: collectionReminders ?? this.collectionReminders,
      specialPickupUpdates: specialPickupUpdates ?? this.specialPickupUpdates,
      serviceUpdates: serviceUpdates ?? this.serviceUpdates,
    );
  }
}

/// Firestore document `users/{uid}`.
///
/// [role] is assigned by the backend/rules — clients cannot promote themselves.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.addressZone,
    required this.emailVerified,
    required this.createdAt,
    this.lastLogin,
    this.fcmToken,
    this.avatarUrl,
    this.language = 'English',
    this.notificationPrefs = const NotificationPrefs(),
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String addressZone;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? fcmToken;
  final String? avatarUrl;
  final String language;
  final NotificationPrefs notificationPrefs;

  bool get isResident => role == AppRoles.resident;
  bool get isDriver => role == AppRoles.driver;
  bool get isOfficer => role == AppRoles.municipalOfficer;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? AppRoles.resident,
      addressZone: data['addressZone'] as String? ?? '',
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      language: data['language'] as String? ?? 'English',
      notificationPrefs: NotificationPrefs.fromMap(
        data['notificationPrefs'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Payload used only when **creating** a profile. Role is hard-coded
  /// to resident by [UserRepository.createResidentProfile].
  Map<String, dynamic> toCreateMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'addressZone': addressZone,
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
        'avatarUrl': avatarUrl,
        'language': language,
        'notificationPrefs': notificationPrefs.toMap(),
      };

  AppUser copyWith({
    String? name,
    String? phone,
    String? addressZone,
    bool? emailVerified,
    String? fcmToken,
    String? avatarUrl,
    String? language,
    NotificationPrefs? notificationPrefs,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      addressZone: addressZone ?? this.addressZone,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }
}
