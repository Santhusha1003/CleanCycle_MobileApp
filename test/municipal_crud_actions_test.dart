import 'package:cleancycle_mobileapp/theme/app_colors.dart';
import 'package:cleancycle_mobileapp/widgets/common/municipal_crud_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Edit and Delete use the shared green/pink design and callbacks',
    (tester) async {
      var edits = 0;
      var deletes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MunicipalCrudActions(
              onEdit: () => edits++,
              onDelete: () => deletes++,
            ),
          ),
        ),
      );
      final editFinder = find.widgetWithText(ElevatedButton, 'Edit');
      final deleteFinder = find.widgetWithText(OutlinedButton, 'Delete');
      final edit = tester.widget<ElevatedButton>(editFinder);
      final delete = tester.widget<OutlinedButton>(deleteFinder);
      final states = <WidgetState>{};
      expect(edit.style!.backgroundColor!.resolve(states), AppColors.primary);
      expect(edit.style!.foregroundColor!.resolve(states), Colors.white);
      expect(
        delete.style!.backgroundColor!.resolve(states),
        const Color(0xFFFFF4F4),
      );
      expect(delete.style!.foregroundColor!.resolve(states), AppColors.error);
      expect(
        delete.style!.side!.resolve(states),
        const BorderSide(color: AppColors.error, width: 1.2),
      );
      for (final style in [edit.style!, delete.style!]) {
        expect(style.minimumSize!.resolve(states), const Size(48, 48));
        expect(
          style.padding!.resolve(states),
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
        final text = style.textStyle!.resolve(states)!;
        expect(text.fontSize, 16);
        expect(text.fontWeight, FontWeight.w600);
        final shape = style.shape!.resolve(states)! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(12));
      }
      for (final icon in [Icons.edit_outlined, Icons.delete_outline]) {
        expect(tester.widget<Icon>(find.byIcon(icon)).size, 18);
      }
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.edit_outlined))).color,
        Colors.white,
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.delete_outline))).color,
        AppColors.error,
      );
      expect(
        tester.getSize(editFinder).height,
        tester.getSize(deleteFinder).height,
      );
      await tester.tap(editFinder);
      await tester.tap(deleteFinder);
      expect(edits, 1);
      expect(deletes, 1);
    },
  );

  for (final width in [320.0, 180.0]) {
    testWidgets('Action row fits $width logical pixels without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: MunicipalCrudActions(onEdit: () {}, onDelete: () {}),
            ),
          ),
        ),
      );
      final edit = tester.getRect(find.widgetWithText(ElevatedButton, 'Edit'));
      final delete = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Delete'),
      );
      if (width == 320) {
        expect(edit.top, delete.top);
        expect(delete.left - edit.right, 12);
      } else {
        expect(delete.top - edit.bottom, 8);
      }
      expect(edit.width, lessThanOrEqualTo(width));
      expect(delete.width, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Disabled callbacks remain disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MunicipalCrudActions(onEdit: null, onDelete: null),
        ),
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });
}
