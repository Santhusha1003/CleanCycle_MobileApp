import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleancycle_mobileapp/collection_schedule/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/collection_schedule/services/collection_schedule_service.dart';
import 'package:cleancycle_mobileapp/collection_schedule/services/missed_collection_report_service.dart';
import 'package:cleancycle_mobileapp/collection_schedule/screens/missed_collection_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Local Firestore snapshots exercise the actual service reader without Firebase.
// ignore: subtype_of_sealed_class
class _Document implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Document(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.documents, {this.error});
  final List<_Document> documents;
  final Exception? error;
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      error == null ? Stream.value(_Snapshot(documents)) : Stream.error(error!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Firestore implements FirebaseFirestore {
  _Firestore(this.reference);
  final _Collection reference;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'resident_schedules');
    return reference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reports implements MissedCollectionReportService {
  final calls = <Map<String, dynamic>>[];
  @override
  Future<String> submitReport({
    required String scheduleId,
    required String wasteType,
    required DateTime collectionDate,
    required String reason,
    required String description,
  }) async {
    calls.add({
      'scheduleId': scheduleId,
      'wasteType': wasteType,
      'collectionDate': collectionDate,
      'reason': reason,
      'description': description,
    });
    return 'local-report-id';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _data(Object? date, {String waste = 'general'}) => {
  'collectionDate': date,
  'wasteType': waste,
  'status': 'completed',
  'startTime': '08:00',
  'endTime': '10:00',
  'acceptedItems': ['Paper'],
  'instructions': 'Keep paper dry.',
};

CollectionScheduleService _service(List<_Document> docs) =>
    CollectionScheduleService(firestore: _Firestore(_Collection(docs)));

Future<void> _open(
  WidgetTester tester,
  CollectionScheduleService service,
  _Reports reports,
) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MissedCollectionReportScreen(
        scheduleService: service,
        reportService: reports,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final instant = DateTime.utc(2025, 1, 15, 8, 45, 30, 123, 456);
  for (final value in <(String, Object)>[
    ('Timestamp', Timestamp.fromDate(instant)),
    ('DateTime', instant),
    ('ISO', instant.toIso8601String()),
    ('ISO offset', '2025-01-15T10:45:30.123456+02:00'),
  ]) {
    test('${value.$1} preserves the instant, time and schedule fields', () {
      final model = CollectionSchedule.fromMap('schedule-id', _data(value.$2));
      expect(model.collectionDate, instant.toLocal());
      expect(
        model.collectionDate.microsecondsSinceEpoch,
        instant.microsecondsSinceEpoch,
      );
      expect(model.id, 'schedule-id');
      expect(model.startTime, '08:00');
      expect(model.endTime, '10:00');
      expect(
        model.toMap()['collectionDate'],
        instant.toLocal().toIso8601String(),
      );
    });
  }
  for (final value in <Object?>[null, '', 'not-a-date', 123, {}]) {
    test(
      'Invalid/missing date $value is rejected without fabricating today',
      () {
        expect(
          () => CollectionSchedule.fromMap('bad', _data(value)),
          throwsFormatException,
        );
      },
    );
  }
  test('Resident schedule service reads the safe projection fields', () async {
    final schedule = (await _service([
      _Document('public-id', _data(Timestamp.fromDate(instant))),
    ]).getSchedules().first).single;
    expect(CollectionScheduleService.collectionName, 'resident_schedules');
    expect(schedule.id, 'public-id');
    expect(schedule.wasteType, 'general');
    expect(schedule.startTime, '08:00');
    expect(schedule.endTime, '10:00');
    expect(schedule.status, 'completed');
    expect(schedule.acceptedItems, ['Paper']);
    expect(schedule.instructions, 'Keep paper dry.');
  });
  test(
    'One invalid document does not break valid schedule stream entries',
    () async {
      final schedules = await _service([
        _Document('timestamp', _data(Timestamp.fromDate(instant))),
        _Document('invalid', _data('not-a-date')),
        _Document('datetime', _data(instant)),
        _Document('missing', {'status': 'completed'}),
        _Document('iso', _data(instant.toIso8601String())),
      ]).getSchedules().first;
      expect(schedules.map((entry) => entry.id), [
        'timestamp',
        'datetime',
        'iso',
      ]);
      expect(
        schedules.map((entry) => entry.collectionDate),
        everyElement(instant.toLocal()),
      );
    },
  );
  test(
    'Only invalid documents yield an empty list, not a stream error',
    () async {
      expect(
        await _service([_Document('bad', _data(null))]).getSchedules().first,
        isEmpty,
      );
    },
  );
  testWidgets(
    'Real missed-report dropdown displays mixed date types and preserves submit payload',
    (tester) async {
      final reports = _Reports();
      await _open(
        tester,
        _service([
          _Document(
            'timestamp',
            _data(Timestamp.fromDate(instant), waste: 'Timestamp waste'),
          ),
          _Document('bad', _data('invalid')),
          _Document('datetime', _data(instant, waste: 'DateTime waste')),
          _Document(
            'iso',
            _data(instant.toIso8601String(), waste: 'ISO waste'),
          ),
        ]),
        reports,
      );
      expect(find.textContaining('Error loading schedules'), findsNothing);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );
      final items = tester
          .widget<DropdownButton<String>>(
            find.descendant(
              of: find.byType(DropdownButtonFormField<String>).first,
              matching: find.byType(DropdownButton<String>),
            ),
          )
          .items!;
      expect(items.map((item) => item.value), ['timestamp', 'datetime', 'iso']);
      expect(dropdown.onChanged, isNotNull);
      expect((items.first.child as Text).data, '15 Jan 2025 - Timestamp waste');
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 Jan 2025 - Timestamp waste').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Waste was not collected').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Waste was left behind at the collection point.',
      );
      await tester.ensureVisible(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();
      expect(reports.calls, [
        {
          'scheduleId': 'timestamp',
          'wasteType': 'Timestamp waste',
          'collectionDate': instant.toLocal(),
          'reason': 'Waste was not collected',
          'description': 'Waste was left behind at the collection point.',
        },
      ]);
      expect(
        find.text('Missed collection report submitted successfully.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Invalid schedules keep the empty form and disable submission', (
    tester,
  ) async {
    final reports = _Reports();
    await _open(tester, _service([_Document('bad', _data(null))]), reports);
    expect(
      find.text('No previous collection schedules available.'),
      findsOneWidget,
    );
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Submit Report'),
    );
    expect(button.onPressed, isNull);
    expect(reports.calls, isEmpty);
  });
  testWidgets('Schedule query errors still show existing load error state', (
    tester,
  ) async {
    final collection = _Collection([], error: Exception('permission-denied'));
    await _open(
      tester,
      CollectionScheduleService(firestore: _Firestore(collection)),
      _Reports(),
    );
    expect(find.textContaining('Error loading schedules:'), findsOneWidget);
  });
}
