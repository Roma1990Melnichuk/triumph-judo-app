/// E2E тести для BeltLevelPicker.
/// Перевіряє: минулі пояси — галочка ✓, поточний — виділений, майбутні — без галочки.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/shared/widgets/belt_level_picker.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _build(BeltLevel initial, {ValueChanged<BeltLevel>? onChanged}) {
  // current оголошено ЗА МЕЖАМИ builder, щоб не скидатись при setState
  BeltLevel current = initial;
  return MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (_, setState) {
          return BeltLevelPicker(
            value: current,
            onChanged: (b) {
              setState(() => current = b);
              onChanged?.call(b);
            },
          );
        },
      ),
    ),
  );
}

/// Кількість галочок (Icons.check) серед чіпів поясів.
int _checkCount(WidgetTester tester) =>
    tester.widgetList(find.byIcon(Icons.check)).length;

/// Знаходить чіп з текстом [name].
Finder _chip(String name) => find.text(name);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BeltLevelPicker — перший пояс (білий)', () {
    testWidgets('жодної галочки — немає попередніх', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.white));
      await tester.pump();
      expect(_checkCount(tester), 0);
    });

    testWidgets('всі пояси відображаються', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.white));
      await tester.pump();
      expect(find.text(BeltLevel.white.displayName), findsOneWidget);
      expect(find.text(BeltLevel.black.displayName), findsOneWidget);
    });
  });

  group('BeltLevelPicker — помаранчевий пояс (index=4)', () {
    testWidgets('рівно 4 галочки (білий, біло-жовтий, жовтий, жовто-помаранчевий)', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();
      expect(_checkCount(tester), 4);
    });

    testWidgets('на поточному поясі — без галочки', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();
      // Знаходимо Row, що містить текст "Помаранчевий"
      final orangeRow = find.ancestor(
        of: find.text('Помаранчевий'),
        matching: find.byType(Row),
      ).first;
      // У цьому Row не повинно бути іконки check
      expect(
        find.descendant(of: orangeRow, matching: find.byIcon(Icons.check)),
        findsNothing,
      );
    });

    testWidgets('майбутні пояси — без галочки', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();

      for (final b in BeltLevel.values.where((b) => b.index > BeltLevel.orange.index)) {
        final row = find.ancestor(
          of: find.text(b.displayName),
          matching: find.byType(Row),
        ).first;
        expect(
          find.descendant(of: row, matching: find.byIcon(Icons.check)),
          findsNothing,
          reason: '${b.displayName} — майбутній, не повинен мати галочку',
        );
      }
    });

    testWidgets('минулі пояси — з галочкою', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();

      for (final b in BeltLevel.values.where((b) => b.index < BeltLevel.orange.index)) {
        final row = find.ancestor(
          of: find.text(b.displayName),
          matching: find.byType(Row),
        ).first;
        expect(
          find.descendant(of: row, matching: find.byIcon(Icons.check)),
          findsOneWidget,
          reason: '${b.displayName} — минулий, має мати галочку',
        );
      }
    });
  });

  group('BeltLevelPicker — чорний пояс (останній)', () {
    testWidgets('всі пояси крім чорного мають галочку', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.black));
      await tester.pump();
      expect(_checkCount(tester), BeltLevel.values.length - 1);
    });
  });

  group('BeltLevelPicker — тап змінює вибраний пояс', () {
    testWidgets('тап на зелений → 6 галочок', (tester) async {
      BeltLevel? changed;
      await tester.pumpWidget(_build(
        BeltLevel.white,
        onChanged: (b) => changed = b,
      ));
      await tester.pump();

      expect(_checkCount(tester), 0);

      await tester.tap(_chip(BeltLevel.green.displayName));
      await tester.pump();

      expect(changed, BeltLevel.green);
      expect(_checkCount(tester), BeltLevel.green.index); // 6 попередніх
    });

    testWidgets('тап на жовтий → 2 галочки (білий і біло-жовтий)', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();

      await tester.tap(_chip(BeltLevel.yellow.displayName));
      await tester.pump();

      expect(_checkCount(tester), BeltLevel.yellow.index); // 2
    });

    testWidgets('тап на білий → 0 галочок', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.green));
      await tester.pump();

      await tester.tap(_chip(BeltLevel.white.displayName));
      await tester.pump();

      expect(_checkCount(tester), 0);
    });
  });

  group('BeltLevelPicker — кількість чіпів', () {
    testWidgets('відображає всі 12 поясів', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.white));
      await tester.pump();
      expect(BeltLevel.values.length, 12);
      for (final b in BeltLevel.values) {
        expect(find.text(b.displayName), findsOneWidget,
            reason: '${b.displayName} має відображатись');
      }
    });
  });

  group('BeltLevelPicker — overflow відсутній', () {
    testWidgets('жодного overflow при помаранчевому поясі', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.orange));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('жодного overflow при чорному поясі', (tester) async {
      await tester.pumpWidget(_build(BeltLevel.black));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
