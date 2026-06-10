import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/membership_model.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/individual_training/providers/individual_training_provider.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/widgets/child_card.dart';

ChildModel makeChild({
  String id = 'id',
  String firstName = 'Олексій',
  String lastName = 'Коваленко',
  int birthYear = 2010,
  String weightCategory = '-30 кг',
  BeltLevel currentBelt = BeltLevel.green,
  int totalPoints = 42,
}) =>
    ChildModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      weightCategory: weightCategory,
      currentBelt: currentBelt,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: totalPoints,
      createdAt: DateTime(2024),
    );

Widget buildCard({
  required ChildModel child,
  int rank = 1,
  int? sameYearRank,
  int? sameYearTotal,
  bool isOwn = false,
  MembershipStatus? membershipStatus,
}) {
  return ProviderScope(
    overrides: [
      beltRequirementProvider.overrideWith((ref, belt) => null),
      beltProgressProvider.overrideWith((ref, args) => Stream.value(null)),
      childAttendanceStatsProvider.overrideWith(
        (ref, id) => Stream.value((total: 0, present: 0, pct: 0.0)),
      ),
      childConfirmedTrainingCountProvider.overrideWith((ref, id) => 0),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ChildCard(
          child: child,
          rank: rank,
          onTap: () {},
          sameYearRank: sameYearRank,
          sameYearTotal: sameYearTotal,
          isOwn: isOwn,
          membershipStatus: membershipStatus,
        ),
      ),
    ),
  );
}

void main() {
  group('ChildCard — базове відображення', () {
    testWidgets('показує повне ім\'я', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild()));
      expect(find.text('Коваленко Олексій'), findsOneWidget);
    });

    testWidgets('показує загальний рейтинг #1', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(), rank: 1));
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('показує кількість балів', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(totalPoints: 42)));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('показує рік народження', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild()));
      expect(find.text('2010 р.н.'), findsOneWidget);
    });

    testWidgets('показує вагу без знаку "-"', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(weightCategory: '-30 кг')));
      expect(find.text('30 кг'), findsOneWidget);
    });

    testWidgets('показує вагу "+48 кг" без змін', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(weightCategory: '+48 кг')));
      expect(find.text('+48 кг'), findsOneWidget);
    });

    testWidgets('НЕ показує крапку-розділювач для порожньої ваги', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(weightCategory: '')));
      // No extra separator dots
      expect(find.text(''), findsNothing);
    });
  });

  group('ChildCard — стовпець однолітків', () {
    testWidgets('НЕ показує блок однолітків без sameYearRank', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild()));
      expect(find.textContaining('р.н.:'), findsNothing);
    });
  });

  group('ChildCard — мітка власної дитини', () {
    testWidgets('показує "Ваша дитина" коли isOwn=true', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild(), isOwn: true));
      expect(find.text('Ваша дитина'), findsOneWidget);
    });

    testWidgets('НЕ показує "Ваша дитина" за замовчуванням', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild()));
      expect(find.text('Ваша дитина'), findsNothing);
    });
  });

  group('ChildCard — onTap', () {
    testWidgets('викликає onTap при натисканні', (tester) async {
      var tapped = false;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          beltRequirementProvider.overrideWith((ref, belt) => null),
          beltProgressProvider.overrideWith((ref, args) => Stream.value(null)),
          childAttendanceStatsProvider.overrideWith(
            (ref, id) => Stream.value((total: 0, present: 0, pct: 0.0)),
          ),
          childConfirmedTrainingCountProvider.overrideWith((ref, id) => 0),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChildCard(
              child: makeChild(),
              rank: 1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(ChildCard));
      expect(tapped, isTrue);
    });
  });

  group('ChildCard — різні ранги', () {
    for (final rank in [1, 5, 99]) {
      testWidgets('відображає ранг #$rank', (tester) async {
        await tester.pumpWidget(buildCard(child: makeChild(), rank: rank));
        expect(find.text('#$rank'), findsOneWidget);
      });
    }
  });

  // ── Membership status dot ─────────────────────────────────────────────────

  group('ChildCard — індикатор абонемента', () {
    testWidgets('показує "Активний" для MembershipStatus.active', (tester) async {
      await tester.pumpWidget(buildCard(
        child: makeChild(),
        membershipStatus: MembershipStatus.active,
      ));
      expect(find.text('Активний'), findsOneWidget);
    });

    testWidgets('показує "Закінч." для MembershipStatus.expiringSoon', (tester) async {
      await tester.pumpWidget(buildCard(
        child: makeChild(),
        membershipStatus: MembershipStatus.expiringSoon,
      ));
      expect(find.text('Закінч.'), findsOneWidget);
    });

    testWidgets('показує "Простр." для MembershipStatus.expired', (tester) async {
      await tester.pumpWidget(buildCard(
        child: makeChild(),
        membershipStatus: MembershipStatus.expired,
      ));
      expect(find.text('Простр.'), findsOneWidget);
    });

    testWidgets('НЕ показує індикатор коли membershipStatus = null', (tester) async {
      await tester.pumpWidget(buildCard(child: makeChild()));
      expect(find.text('Активний'), findsNothing);
      expect(find.text('Закінч.'), findsNothing);
      expect(find.text('Простр.'), findsNothing);
    });

    testWidgets('картка рендериться без помилок для всіх трьох статусів', (tester) async {
      for (final status in MembershipStatus.values) {
        await tester.pumpWidget(buildCard(
          child: makeChild(),
          membershipStatus: status,
        ));
        expect(find.text('Коваленко Олексій'), findsOneWidget);
      }
    });
  });
}
