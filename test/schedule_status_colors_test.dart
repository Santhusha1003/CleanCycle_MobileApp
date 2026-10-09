import 'package:cleancycle_mobileapp/models/collection_schedule.dart';
import 'package:cleancycle_mobileapp/screens/schedule_management_screen.dart';
import 'package:cleancycle_mobileapp/services/municipal/schedule_service.dart';
import 'package:cleancycle_mobileapp/theme/app_colors.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_status_card.dart';
import 'package:cleancycle_mobileapp/widgets/common/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _expected = {
  'scheduled': (
    'Scheduled',
    Color(0xFFEAF4FF),
    Color(0xFF215A9B),
    Icons.event_outlined,
  ),
  'in_progress': (
    'In Progress',
    Color(0xFFFFF4DE),
    Color(0xFF8A5300),
    Icons.timelapse_outlined,
  ),
  'completed': (
    'Completed',
    AppColors.greenSurface,
    AppColors.primaryDark,
    Icons.check_circle_outline,
  ),
  'cancelled': (
    'Cancelled',
    Color(0xFFFFEAEA),
    Color(0xFF9F3030),
    Icons.cancel_outlined,
  ),
};

// UI-only fixtures: no Firebase reads/writes.
class _Schedules implements ScheduleService {
  final records = _expected.keys
      .map(
        (status) => CollectionSchedule(
          scheduleId: status,
          zone: 'Zone $status',
          collectionDate: DateTime(2026, 10, 9),
          startTime: '08:00',
          endTime: '12:00',
          wasteType: 'general',
          status: status,
          createdAt: null,
          updatedAt: null,
        ),
      )
      .toList();

  @override
  Future<List<CollectionSchedule>> getSchedules() async => List.of(records);

  @override
  Future<void> updateSchedule({
    required String scheduleId,
    required CollectionSchedule schedule,
  }) async {
    records[records.indexWhere((entry) => entry.scheduleId == scheduleId)] =
        schedule;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openScreen(WidgetTester tester, {_Schedules? service}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleManagementScreen(scheduleService: service ?? _Schedules()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _statusField => find.byWidgetPredicate(
  (widget) =>
      widget is DropdownButtonFormField<String> &&
      widget.decoration.labelText == 'Status',
);

void _expectSelected(WidgetTester tester, String status) {
  final expected = _expected[status]!;
  final field = tester.widget<DropdownButtonFormField<String>>(_statusField);
  expect(field.decoration.filled, isTrue);
  expect(field.decoration.fillColor, expected.$2);
  final icon = field.decoration.prefixIcon! as Icon;
  expect(icon.icon, expected.$4);
  expect(icon.color, expected.$3);
  final dropdown = tester.widget<DropdownButton<String>>(
    find.descendant(
      of: _statusField,
      matching: find.byType(DropdownButton<String>),
    ),
  );
  expect(dropdown.value, status);
  expect(dropdown.iconEnabledColor, expected.$3);
  for (final text in dropdown.selectedItemBuilder!(
    tester.element(_statusField),
  )) {
    final selectedText = text as Text;
    expect(
      selectedText.style!.color,
      _expected.values.firstWhere((entry) => entry.$1 == selectedText.data).$3,
    );
  }
}

void main() {
  testWidgets('All existing schedule cards use the status palette', (
    tester,
  ) async {
    await _openScreen(tester);
    for (final entry in _expected.entries) {
      await tester.scrollUntilVisible(
        find.text(entry.value.$1),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      final badge = tester.widget<AppStatusCard>(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppStatusCard && widget.statusText == entry.value.$1,
        ),
      );
      final cardFinder = find.ancestor(
        of: find.text('Zone ${entry.key}'),
        matching: find.byType(AppCard),
      );
      expect(tester.widget<AppCard>(cardFinder).color, entry.value.$2);
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(of: cardFinder, matching: find.byType(Material))
                  .first,
            )
            .color,
        entry.value.$2,
      );
      expect(badge.color, entry.value.$2);
      expect(badge.textColor, entry.value.$3);
    }
  });

  testWidgets(
    'Saving each status updates the entire card without manual refresh',
    (tester) async {
      final service = _Schedules();
      await _openScreen(tester, service: service);
      for (final entry in _expected.entries) {
        final card = find.ancestor(
          of: find.text('Zone scheduled'),
          matching: find.byType(AppCard),
        );
        await tester.tap(
          find.descendant(of: card, matching: find.text('Edit')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(_statusField);
        await tester.pumpAndSettle();
        await tester.tap(_statusField);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.value.$1).last);
        await tester.pumpAndSettle();
        _expectSelected(tester, entry.key);
        await tester.ensureVisible(find.text('Update Schedule'));
        await tester.tap(find.text('Update Schedule'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(service.records.first.status, entry.key);
        expect(tester.widget<AppCard>(card).color, entry.value.$2);
        final badge = tester.widget<AppStatusCard>(
          find.descendant(of: card, matching: find.byType(AppStatusCard)),
        );
        expect(badge.color, entry.value.$2);
        expect(badge.textColor, entry.value.$3);
      }
    },
  );

  for (final edit in [false, true]) {
    testWidgets(
      '${edit ? 'Edit' : 'Add'} status options and selected colors update immediately',
      (tester) async {
        await _openScreen(tester);
        await tester.tap(find.text(edit ? 'Edit' : 'Add Schedule').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(_statusField);
        await tester.pumpAndSettle();
        _expectSelected(tester, 'scheduled');
        for (final entry in _expected.entries) {
          await tester.tap(_statusField);
          await tester.pumpAndSettle();
          // The menu options use the same pastel background and dark text.
          final option = tester.widget<AppStatusCard>(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is AppStatusCard &&
                      widget.statusText == entry.value.$1,
                )
                .last,
          );
          expect(option.color, entry.value.$2);
          expect(option.textColor, entry.value.$3);
          await tester.tap(find.text(entry.value.$1).last);
          await tester.pumpAndSettle();
          _expectSelected(tester, entry.key);
        }
      },
    );
  }
}
