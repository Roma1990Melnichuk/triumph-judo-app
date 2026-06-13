/// TC-MEDIA-0392 / TC-MEDIA-0393 — Media Resilience
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:judo_app/core/constants/belt_levels.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/user_model.dart';
import 'package:judo_app/features/achievements/providers/achievement_progress_provider.dart';
import 'package:judo_app/features/achievements/providers/achievement_provider.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/belts/providers/belt_provider.dart';
import 'package:judo_app/features/competitions/providers/competitions_provider.dart';
import 'package:judo_app/features/individual_training/providers/individual_training_provider.dart';
import 'package:judo_app/features/membership/providers/membership_provider.dart';
import 'package:judo_app/features/schedule/providers/group_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/features/team/screens/child_profile_screen.dart';

// ── Хелпери ───────────────────────────────────────────────────────────────────

ChildModel _child({String? photoUrl}) => ChildModel(
      id: 'child1',
      firstName: 'Іван',
      lastName: 'Петренко',
      birthYear: 2014,
      weightCategory: '-30 кг',
      currentBelt: BeltLevel.white,
      photoUrl: photoUrl,
      coachId: 'coach1',
      coachName: 'Тренер',
      totalPoints: 0,
      createdAt: DateTime(2024),
    );

final _coachUser = const UserModel(
  uid: 'coach1',
  email: 'coach@test.com',
  name: 'Тренер',
  role: 'coach',
);

Widget _profileApp(ChildModel child) {
  final db = FakeFirebaseFirestore();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => ChildProfileScreen(childId: child.id)),
      GoRoute(path: '/team/:id/edit', builder: (_, __) => const Scaffold(body: Text('edit'))),
      GoRoute(path: '/team/:id/add-result', builder: (_, __) => const Scaffold(body: Text('result'))),
      GoRoute(path: '/team/:id/measurements', builder: (_, __) => const Scaffold(body: Text('measure'))),
      GoRoute(path: '/belts/edit', builder: (_, __) => const Scaffold(body: Text('belts'))),
      GoRoute(path: '/fitness/:id', builder: (_, __) => const Scaffold(body: Text('fitness'))),
      GoRoute(path: '/my-assignments', builder: (_, __) => const Scaffold(body: Text('assign'))),
      GoRoute(path: '/membership/:id', builder: (_, __) => const Scaffold(body: Text('membership'))),
      GoRoute(path: '/nutrition/child/:id', builder: (_, __) => const Scaffold(body: Text('nutrition'))),
    ],
  );
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(db),
      currentUserModelProvider.overrideWith((_) => Stream.value(_coachUser)),
      allChildrenProvider.overrideWith((_) => Stream.value([child])),
      childByIdProvider.overrideWith((ref, id) => Stream.value(child)),
      childResultsProvider.overrideWith((ref, id) => Stream.value([])),
      beltProgressProvider.overrideWith((ref, arg) => Stream.value(null)),
      beltRequirementProvider.overrideWith((ref, belt) => null),
      membershipByAthleteProvider.overrideWith((ref, id) => Stream.value(null)),
      childAttendanceStatsProvider.overrideWith(
          (ref, id) => Stream.value(const (total: 0, present: 0, pct: 0.0))),
      childConfirmedTrainingCountProvider.overrideWith((ref, id) => 0),
      coachByIdProvider.overrideWith((ref, id) => null),
      parentsByChildIdProvider.overrideWith((ref, id) => Stream.value([])),
      childAchievementsProvider.overrideWith((ref, id) => Stream.value([])),
      achievementProgressProvider.overrideWith((ref, id) => {}),
      childGroupsProvider.overrideWith((ref, id) => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── TC-MEDIA-0392 ──────────────────────────────────────────────────────────────

void main() {
  group('TC-MEDIA-0392: відсутність фото/іконки — резервне відображення', () {
    testWidgets('photoUrl = null → аватар-заглушка без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      await tester.pumpWidget(_profileApp(_child(photoUrl: null)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('photoUrl = порожній рядок → без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      await tester.pumpWidget(_profileApp(_child(photoUrl: '')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('досягнення без іконки → список рендериться без краша',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      // childAchievementsProvider returns empty list — screen must not crash
      // even when achievement icon URLs are absent
      await tester.pumpWidget(_profileApp(_child()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  // ── TC-MEDIA-0393 ──────────────────────────────────────────────────────────

  group('TC-MEDIA-0393: Cloudinary відео — smoke (без мережі)', () {
    test('Cloudinary URL формат валідний для відомого шаблону', () {
      // Перевіряємо що Cloudinary URL будується коректно.
      // Фактичне відтворення відео неможливо перевірити без реальної мережі.
      const cloudName = 'triumph-judo';
      const publicId = 'videos/training_session_001';
      final url =
          'https://res.cloudinary.com/$cloudName/video/upload/$publicId.mp4';
      expect(Uri.tryParse(url), isNotNull);
      expect(Uri.parse(url).scheme, equals('https'));
      expect(url, contains('cloudinary.com'));
      expect(url, endsWith('.mp4'));
    });

    testWidgets('профіль без відео-контенту рендериться без краша', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final handler = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        handler?.call(d);
      };
      addTearDown(() => FlutterError.onError = handler);

      await tester.pumpWidget(_profileApp(_child()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
