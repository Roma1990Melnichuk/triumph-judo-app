/// E2E тести: довгий текст не ламає layout на всіх екранах і розмірах.
/// Перевіряє ChildCard, TeamListScreen з максимально довгими іменами.
/// Розміри: 320x568, 390x844, 430x932. textScaleFactor: 1.0, 1.3, 1.6.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/team_list_screen.dart';
import 'package:judo_app/features/team/widgets/child_card.dart';

const _longFirstName =
    'Олександр-Максиміліан-Фернандо-Станіславович Коваленко-Петренко-Де-Ла-Крус';
const _longLastName = 'Шевченко-Григорович-Левицький-Задорожній';
const _longComment =
    'Дуже довгий коментар тренера, який повинен переноситися на кілька рядків і не ламати картку, список, bottom navigation або кнопку дії.';
const _noSpaces =
    'ОлександрМаксиміліанФернандоСтаніславовичКоваленкоПетренко';

const _screenSizes = <({String label, Size size})>[
  (label: '320x568', size: Size(320, 568)),
  (label: '390x844', size: Size(390, 844)),
  (label: '430x932', size: Size(430, 932)),
];
const _textScaleFactors = [1.0, 1.3, 1.6];

ChildModel _longChild({String id = 'child-long'}) => ChildModel(
      id: id,
      firstName: _longFirstName,
      lastName: _longLastName,
      birthYear: 2012,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      coachId: 'coach1',
      coachName: _longFirstName,
      totalPoints: 42,
      createdAt: DateTime(2024, 1, 1),
      gender: Gender.male,
    );

ChildModel _noSpacesChild({String id = 'child-ns'}) => ChildModel(
      id: id,
      firstName: _noSpaces,
      lastName: _noSpaces,
      birthYear: 2013,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.yellow,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 10,
      createdAt: DateTime(2024, 1, 1),
    );

final _coach = UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: _longFirstName,
  role: 'coach',
);

Widget _teamApp(List<ChildModel> children) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allChildrenProvider.overrideWith((_) => Stream.value(children)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
      firestoreProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/team',
        routes: [
          GoRoute(path: '/team', builder: (_, __) => const TeamListScreen()),
          GoRoute(path: '/team/add', builder: (_, __) => const Scaffold(body: Text('add'))),
          GoRoute(path: '/team/:id', builder: (_, __) => const Scaffold(body: Text('profile'))),
        ],
      ),
    ),
  );
}

Widget _childCardWidget(ChildModel child) {
  final db = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(_coach)),
      allMembershipsProvider.overrideWith((_) => Stream.value(const [])),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: double.infinity,
          child: ChildCard(child: child, rank: 1, onTap: () {}, showAttendance: false),
        ),
      ),
    ),
  );
}

Future<void> _runAtSize(
  WidgetTester tester, {
  required Size logicalSize,
  required double textScaleFactor,
  required Widget Function() build,
}) async {
  tester.view.physicalSize = logicalSize * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: logicalSize, textScaler: TextScaler.linear(textScaleFactor)),
      child: build(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull,
      reason: 'size=$logicalSize scale=$textScaleFactor: виняток при рендері');
}

void main() {
  group('LongText — ChildCard із довгим іменем', () {
    for (final screen in _screenSizes) {
      for (final scale in _textScaleFactors) {
        testWidgets('${screen.label} × textScale=$scale — longName', (tester) async {
          await _runAtSize(
            tester,
            logicalSize: screen.size,
            textScaleFactor: scale,
            build: () => _childCardWidget(_longChild()),
          );
        });
        testWidgets('${screen.label} × textScale=$scale — noSpaces', (tester) async {
          await _runAtSize(
            tester,
            logicalSize: screen.size,
            textScaleFactor: scale,
            build: () => _childCardWidget(_noSpacesChild()),
          );
        });
      }
    }
  });

  group('LongText — TeamListScreen із довгим прізвищем', () {
    for (final screen in _screenSizes) {
      for (final scale in _textScaleFactors) {
        testWidgets('${screen.label} × textScale=$scale — TeamListScreen', (tester) async {
          final children = [_longChild(id: 'c1'), _noSpacesChild(id: 'c2')];
          await _runAtSize(
            tester,
            logicalSize: screen.size,
            textScaleFactor: scale,
            build: () => _teamApp(children),
          );
        });
      }
    }
  });

  group('LongText — ChildCard без пробілів 320x568 scale=1.6', () {
    testWidgets('noSpaces не overflow', (tester) async {
      await _runAtSize(
        tester,
        logicalSize: const Size(320, 568),
        textScaleFactor: 1.6,
        build: () => _childCardWidget(_noSpacesChild()),
      );
    });
  });

  group('LongText — коментар тренера', () {
    testWidgets('довгий коментар рендериться без overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Column(
                children: [
                  Text(_longComment, softWrap: true, overflow: TextOverflow.visible),
                  Text("Молодша група початківців понеділок-середа-п'ятниця 18:30",
                      softWrap: true, overflow: TextOverflow.visible),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
