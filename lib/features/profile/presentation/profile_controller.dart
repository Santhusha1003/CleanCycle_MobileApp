import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/error_mapper.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/models/app_user.dart';
import '../../auth/presentation/auth_controller.dart';

/// Profile CRUD for Account Settings. Watches `users/{uid}` live.
class ProfileController extends ChangeNotifier {
  ProfileController({
    required UserRepository userRepository,
    required AuthRepository authRepository,
    required AuthController authController,
  })  : _users = userRepository,
        _auth = authRepository,
        _session = authController {
    _session.addListener(_bindToSession);
    _bindToSession();
  }

  final UserRepository _users;
  final AuthRepository _auth;
  final AuthController _session;
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<AppUser?>? _sub;
  String? _uid;

  AppUser? user;
  bool loading = false;
  bool busy = false;
  String? errorMessage;

  void _bindToSession() {
    final uid = _session.firebaseUser?.uid;
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    user = _session.profile;
    if (uid == null) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    _sub = _users.watchById(uid).listen(
      (profile) {
        user = profile;
        loading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = ErrorMapper.from(error);
        loading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? addressZone,
    String? language,
    String? avatarUrl,
  }) {
    return _run(() async {
      final uid = _requireUid();
      await _users.updateProfile(
        uid,
        name: name,
        phone: phone,
        addressZone: addressZone,
        language: language,
        avatarUrl: avatarUrl,
      );
      if (name != null) {
        await _auth.updateDisplayName(name);
      }
    });
  }

  Future<bool> updateNotificationPrefs(NotificationPrefs prefs) {
    return _run(() => _users.updateNotificationPrefs(_requireUid(), prefs));
  }

  /// Gallery pick → copy into app documents → UPDATE `avatarUrl`.
  /// Storage is not in the project stack, so the file stays on-device.
  Future<bool> pickAndSaveAvatar() {
    return _run(() async {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/avatar_$_uid.jpg');
      await File(picked.path).copy(dest.path);
      await _users.updateProfile(_requireUid(), avatarUrl: dest.path);
    });
  }

  /// DELETE: re-authenticate, delete Firestore doc, then Auth user.
  Future<bool> deleteAccount({String? password}) {
    return _run(() async {
      final uid = _requireUid();
      final providers =
          _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
              [];
      if (providers.contains('password')) {
        if (password == null || password.isEmpty) {
          throw StateError('Please confirm your password to delete the account.');
        }
        await _auth.reauthenticateWithPassword(password);
      } else if (providers.contains('google.com')) {
        await _auth.signInWithGoogle();
      }
      try {
        await _users.clearFcmToken(uid);
      } catch (_) {}
      await _users.deleteProfile(uid);
      await _auth.deleteAuthUser();
    });
  }

  Future<void> logout() async {
    final uid = _uid;
    if (uid != null) {
      try {
        await _users.clearFcmToken(uid);
      } catch (_) {}
    }
    await _session.signOut();
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('You need to be signed in.');
    }
    return uid;
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      if (ErrorMapper.isCancelled(error)) return false;
      errorMessage = error is StateError
          ? error.message
          : ErrorMapper.from(error);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_bindToSession);
    _sub?.cancel();
    super.dispose();
  }
}
