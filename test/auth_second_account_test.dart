import 'package:cleancycle_mobileapp/features/auth/data/auth_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/data/user_repository.dart';
import 'package:cleancycle_mobileapp/features/auth/presentation/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  bool get isAnonymous => false;
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthRepository {
  User? user;
  @override
  User? get currentUser => user;
  @override
  Stream<User?> authStateChanges() => const Stream.empty();
  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async => user = _User(email.split('@').first);
  @override
  Future<User?> reloadCurrentUser() async => user;
  @override
  Future<void> signOut() async {
    user = null;
  }
}

// Exercise the real UserRepository and AppUser decoder with per-UID documents.
class _Database implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{
    'first': {
      'uid': 'first',
      'role': 'resident',
      'name': 'First account',
      'email': 'first@example.test',
      'emailVerified': true,
    },
    'second': {
      'role': 'driver',
      'requestedRole': 'driver',
      'name': 'Second account',
      'email': 'second@example.test',
      'emailVerified': true,
    },
  };
  final reads = <String>[];
  final updates = <String>[];
  String? readError;
  String legacyWriteError = 'permission-denied';
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _Collection(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db);
  final _Database db;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(db, path!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.uid);
  final _Database db;
  final String uid;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    db.reads.add(uid);
    if (db.readError != null) {
      throw FirebaseException(plugin: 'cloud_firestore', code: db.readError!);
    }
    return _Snapshot(uid, db.records[uid]);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    // Sign-out also clears the device token; keep audit assertions separate.
    if (!data.containsKey('lastLogin')) return;
    db.updates.add(uid);
    expect(data.keys, ['lastLogin']);
    if (!db.records[uid]!.containsKey('uid')) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: db.legacyWriteError,
      );
    }
    // Firestore resolves serverTimestamp before a subsequent profile read.
    db.records[uid]!['lastLogin'] = Timestamp.fromDate(DateTime(2026, 10, 9));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  SnapshotMetadata get metadata => _Metadata();
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Metadata implements SnapshotMetadata {
  @override
  bool get isFromCache => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Database db;
  late _Auth auth;
  late AuthController controller;
  setUp(() {
    db = _Database();
    auth = _Auth();
    controller = AuthController(
      authRepository: auth,
      userRepository: UserRepository(firestore: db),
      firebaseReady: true,
    );
  });
  tearDown(() => controller.dispose());

  Future<bool> login(String account) => controller.signInWithEmail(
    email: '$account@example.test',
    password: 'local-test-only',
  );

  test(
    'second legacy account loads its own profile despite denied lastLogin',
    () async {
      expect(await login('first'), isTrue);
      expect(controller.profile!.uid, 'first');
      expect(controller.profile!.role, 'resident');
      await controller.signOut();
      expect(await login('second'), isTrue);
      expect(controller.firebaseUser!.uid, 'second');
      expect(controller.profile!.uid, 'second');
      expect(controller.profile!.name, 'Second account');
      expect(controller.profile!.role, 'driver');
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.errorMessage, isNull);
      expect(controller.needsEmailVerification, isFalse);
      expect(db.reads, ['first', 'first', 'second', 'second']);
      expect(db.updates, ['first', 'second']);
      expect(db.records['first']!['lastLogin'], isNotNull);
      expect(db.records['second']!.containsKey('uid'), isFalse);
      expect(db.records['second']!['role'], 'driver');
    },
  );

  test(
    'second account with matching uid still updates lastLogin normally',
    () async {
      db.records['second']!['uid'] = 'second';
      expect(await login('first'), isTrue);
      await controller.signOut();
      expect(await login('second'), isTrue);
      expect(controller.profile!.role, 'driver');
      expect(db.records['second']!['lastLogin'], isNotNull);
    },
  );

  test('profile read permission errors remain blocking', () async {
    db.readError = 'permission-denied';
    expect(await login('second'), isFalse);
    expect(auth.currentUser, isNull);
    expect(controller.profile, isNull);
    expect(controller.errorMessage, isNotNull);
    expect(db.updates, isEmpty);
  });

  test('missing second profile is not created or replaced', () async {
    db.records.remove('second');
    expect(await login('second'), isFalse);
    expect(auth.currentUser, isNull);
    expect(controller.profile, isNull);
    expect(db.updates, isEmpty);
    expect(db.records.containsKey('second'), isFalse);
  });

  test('non-permission timestamp failures are not suppressed', () async {
    db.legacyWriteError = 'unavailable';
    expect(await login('second'), isFalse);
    expect(auth.currentUser, isNull);
    expect(controller.errorMessage, isNotNull);
  });
}
