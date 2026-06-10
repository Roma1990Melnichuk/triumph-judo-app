import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/models/user_model.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/belts/screens/belt_overview_screen.dart';
import 'features/belts/screens/belt_requirements_screen.dart';
import 'features/belts/screens/bulk_belt_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/events/screens/add_edit_event_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/my_data_screen.dart';
import 'features/individual_training/screens/individual_training_screen.dart';
import 'features/fitness/screens/add_assignment_result_screen.dart';
import 'features/fitness/screens/assignment_athletes_screen.dart';
import 'features/fitness/screens/assignment_detail_screen.dart';
import 'features/fitness/screens/assignment_group_progress_screen.dart';
import 'features/fitness/screens/bulk_fitness_goals_screen.dart';
import 'features/fitness/screens/coach_assignments_screen.dart';
import 'features/fitness/screens/create_assignment_wizard_screen.dart';
import 'features/fitness/screens/fitness_exercise_detail_screen.dart';
import 'features/fitness/screens/fitness_screen.dart';
import 'features/fitness/screens/my_assignments_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/journey/screens/journey_screen.dart';
import 'features/membership/screens/checkout_screen.dart';
import 'features/membership/screens/coach_memberships_screen.dart';
import 'features/membership/screens/membership_detail_screen.dart';
import 'features/membership/screens/membership_screen.dart';
import 'features/membership/screens/my_memberships_screen.dart';
import 'features/membership/screens/payment_success_screen.dart';
import 'features/schedule/screens/groups_screen.dart';
import 'features/schedule/screens/group_detail_screen.dart';
import 'features/competitions/screens/add_result_screen.dart';
import 'features/rating/screens/rating_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/team/screens/add_edit_child_screen.dart';
import 'features/achievements/screens/achievement_catalog_screen.dart';
import 'features/achievements/screens/achievement_stats_screen.dart';
import 'features/achievements/screens/bulk_grant_achievements_screen.dart';
import 'features/achievements/screens/grant_achievement_screen.dart';
import 'features/team/screens/child_profile_screen.dart';
import 'features/team/screens/team_list_screen.dart';
import 'shared/widgets/main_scaffold.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

String? computeRedirect({
  required bool isLoading,
  required bool isLoggedIn,
  required String currentPath,
}) {
  if (isLoading) return currentPath == '/splash' ? null : '/splash';
  final onAuth   = currentPath.startsWith('/auth');
  final onSplash = currentPath == '/splash';
  if (onSplash)               return isLoggedIn ? '/home' : '/auth/login';
  if (!isLoggedIn && !onAuth) return '/auth/login';
  if (isLoggedIn  && onAuth)  return '/home';
  return null;
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider,        (_, __) => notifyListeners());
    ref.listen(currentUserModelProvider, (_, __) => notifyListeners());
  }
}

// ── Page transition helpers ───────────────────────────────────────────────────

CustomTransitionPage<void> _fadeSlide(
    GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.025), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _fadeScale(
    GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userModel = ref.read(currentUserModelProvider);
      return computeRedirect(
        isLoading: authState.isLoading ||
            (authState.hasValue && userModel.isLoading),
        isLoggedIn: authState.value != null,
        currentPath: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/team/add',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const AddEditChildScreen()),
      ),
      GoRoute(
        path: '/team/:id',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final user = container.read(currentUserModelProvider).value;
          if (user == null || user.isCoach) return null;
          final childId = state.pathParameters['id']!;
          if (user.ownsChild(childId)) return null;
          return '/team';
        },
        pageBuilder: (_, s) => _fadeSlide(s, ChildProfileScreen(childId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/team/:id/edit',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AddEditChildScreen(childId: s.pathParameters['id'])),
      ),
      GoRoute(
        path: '/team/:id/add-result',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AddResultScreen(childId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/schedule',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const GroupsScreen()),
      ),
      GoRoute(
        path: '/group/:id',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, GroupDetailScreen(groupId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/bulk-belt',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final user = ProviderScope.containerOf(context).read(currentUserModelProvider).value;
          if (user == null || !user.isCoach) return '/home';
          return null;
        },
        pageBuilder: (_, s) => _fadeSlide(s, const BulkBeltScreen()),
      ),
      GoRoute(
        path: '/bulk-fitness-goals',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const BulkFitnessGoalsScreen()),
      ),
      GoRoute(
        path: '/membership/:childId',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final user = container.read(currentUserModelProvider).value;
          if (user == null || user.isCoach) return null;
          final childId = state.pathParameters['childId']!;
          if (user.ownsChild(childId)) return null;
          return '/team';
        },
        pageBuilder: (_, s) => _fadeSlide(s, MembershipScreen(childId: s.pathParameters['childId']!)),
      ),
      GoRoute(
        path: '/belts/edit',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const BeltRequirementsScreen()),
      ),
      GoRoute(
        path: '/achievements',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final user = ProviderScope.containerOf(context).read(currentUserModelProvider).value;
          if (user == null || !user.isCoach) return '/home';
          return null;
        },
        pageBuilder: (_, s) => _fadeScale(s, const GrantAchievementScreen()),
      ),
      GoRoute(
        path: '/bulk-achievements',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final user = ProviderScope.containerOf(context).read(currentUserModelProvider).value;
          if (user == null || !user.isCoach) return '/home';
          return null;
        },
        pageBuilder: (_, s) => _fadeScale(s, const BulkGrantAchievementsScreen()),
      ),
      GoRoute(
        path: '/achievement-stats',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final user = ProviderScope.containerOf(context).read(currentUserModelProvider).value;
          if (user == null || !user.isCoach) return '/home';
          return null;
        },
        pageBuilder: (_, s) => _fadeScale(s, const AchievementStatsScreen()),
      ),
      GoRoute(
        path: '/achievement-catalog',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(
            s,
            AchievementCatalogScreen(
                childId: s.uri.queryParameters['childId'])),
      ),
      GoRoute(
        path: '/events/add',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const AddEditEventScreen()),
      ),
      GoRoute(
        path: '/events/:id/edit',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AddEditEventScreen(eventId: s.pathParameters['id'])),
      ),
      GoRoute(
        path: '/individual-training',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const IndividualTrainingScreen()),
      ),
      GoRoute(
        path: '/fitness/:childId',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final user = container.read(currentUserModelProvider).value;
          if (user == null || user.isCoach) return null;
          final childId = state.pathParameters['childId']!;
          if (user.ownsChild(childId)) return null;
          return '/team';
        },
        pageBuilder: (_, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          return _fadeSlide(s, FitnessScreen(
            childId: s.pathParameters['childId']!,
            childName: extra['childName'] as String? ?? '',
          ));
        },
      ),
      GoRoute(
        path: '/fitness/:childId/exercise/:exerciseId',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final user = container.read(currentUserModelProvider).value;
          if (user == null || user.isCoach) return null;
          final childId = state.pathParameters['childId']!;
          if (user.ownsChild(childId)) return null;
          return '/team';
        },
        pageBuilder: (_, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          return _fadeSlide(s, FitnessExerciseDetailScreen(
            childId: s.pathParameters['childId']!,
            exerciseId: s.pathParameters['exerciseId']!,
            exerciseName: extra['name'] as String? ?? '',
            exerciseUnit: extra['unit'] as String? ?? 'рази',
          ));
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/journey',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const JourneyScreen()),
      ),
      GoRoute(
        path: '/my-data',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const MyDataScreen()),
      ),
      GoRoute(
        path: '/abonements',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, MembershipScreen(
          childId: (s.extra as Map?)?['childId'] as String? ?? '',
        )),
      ),
      GoRoute(
        path: '/abonements/detail',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, MembershipDetailScreen(
          tariff: (s.extra as Map)['tariff'] as TariffData,
          childId: (s.extra as Map)['childId'] as String,
        )),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, CheckoutScreen(
          planName: (s.extra as Map)['planName'] as String,
          amount: (s.extra as Map)['amount'] as double,
          childId: (s.extra as Map)['childId'] as String,
          variantMultiplier: (s.extra as Map?)?['variantMultiplier'] as int? ?? 1,
        )),
      ),
      GoRoute(
        path: '/payment-success',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeScale(s, PaymentSuccessScreen(
          planName: (s.extra as Map)['planName'] as String,
          amount: (s.extra as Map)['amount'] as double,
          childId: (s.extra as Map)['childId'] as String,
        )),
      ),
      GoRoute(
        path: '/my-abonements',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, MyMembershipsScreen(
          childId: (s.extra as Map?)?['childId'] as String? ?? '',
        )),
      ),
      GoRoute(
        path: '/membership-management',
        parentNavigatorKey: _rootNavKey,
        redirect: (context, state) {
          final user = ProviderScope.containerOf(context).read(currentUserModelProvider).value;
          if (user == null || !user.isCoach) return '/home';
          return null;
        },
        pageBuilder: (_, s) => _fadeSlide(s, const CoachMembershipsScreen()),
      ),
      // ── Assignments (coach management) ──────────────────────────────────────
      GoRoute(
        path: '/assignments',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, const CoachAssignmentsScreen()),
      ),
      GoRoute(
        path: '/assignments/create',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeScale(s, const CreateAssignmentWizardScreen()),
      ),
      GoRoute(
        path: '/assignments/:assignmentId/progress',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AssignmentGroupProgressScreen(
          assignmentId: s.pathParameters['assignmentId']!,
        )),
      ),
      GoRoute(
        path: '/assignments/:assignmentId/athletes',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AssignmentAthletesScreen(
          assignmentId: s.pathParameters['assignmentId']!,
        )),
      ),
      GoRoute(
        path: '/assignments/:assignmentId/athlete/:childId',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AssignmentDetailScreen(
          assignmentId: s.pathParameters['assignmentId']!,
          childId: s.pathParameters['childId']!,
        )),
      ),
      // ── Assignments (athlete/parent view) ───────────────────────────────────
      GoRoute(
        path: '/my-assignments',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, MyAssignmentsScreen(
          childId: (s.extra as Map?)?['childId'] as String? ?? '',
        )),
      ),
      GoRoute(
        path: '/my-assignments/:assignmentId',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AssignmentDetailScreen(
          assignmentId: s.pathParameters['assignmentId']!,
          childId: (s.extra as Map?)?['childId'] as String? ?? '',
        )),
      ),
      GoRoute(
        path: '/my-assignments/:assignmentId/add-result',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (_, s) => _fadeSlide(s, AddAssignmentResultScreen(
          assignmentId: s.pathParameters['assignmentId']!,
          childId: (s.extra as Map?)?['childId'] as String? ?? '',
          exerciseId: (s.extra as Map?)?['exerciseId'] as String? ?? '',
          exerciseName: (s.extra as Map?)?['exerciseName'] as String? ?? '',
          exerciseUnit: (s.extra as Map?)?['exerciseUnit'] as String? ?? 'рази',
        )),
      ),
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/team',     builder: (_, __) => const TeamListScreen()),
          GoRoute(path: '/rating',   builder: (_, __) => const RatingScreen()),
          GoRoute(path: '/events',   builder: (_, __) => const EventsScreen()),
          GoRoute(path: '/belts',    builder: (_, __) => const BeltOverviewScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Theme helpers
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _inter({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.textPrimary,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class JudoApp extends ConsumerWidget {
  const JudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'Тріумф',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(),
    );
  }

  static ThemeData _theme() => ThemeData(
    useMaterial3: false, // M2 — no automatic surface-tint color derivation
    brightness: Brightness.dark,

    // ── Colors ───────────────────────────────────────────────────────────────
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:     AppColors.primary,
      secondary:   AppColors.accent,
      surface:     AppColors.surface,
      error:       AppColors.error,
      onPrimary:   Colors.white,
      onSecondary: AppColors.fabIcon,
      onSurface:   AppColors.textPrimary,
      onError:     Colors.white,
    ),

    // ── Typography ────────────────────────────────────────────────────────────
    // Inter Medium 16 for card titles, Inter Regular 12-13 for secondary
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: TextTheme(
      displayLarge:   _inter(size: 28, weight: FontWeight.bold),
      headlineLarge:  _inter(size: 24, weight: FontWeight.bold),
      headlineMedium: _inter(size: 20, weight: FontWeight.bold),
      titleLarge:     _inter(size: 18, weight: FontWeight.w700),
      titleMedium:    _inter(size: 16, weight: FontWeight.w500), // card title
      titleSmall:     _inter(size: 14, weight: FontWeight.w600),
      bodyLarge:      _inter(size: 15),
      bodyMedium:     _inter(size: 13, color: AppColors.textSecondary), // secondary
      bodySmall:      _inter(size: 12, color: AppColors.textSecondary), // secondary
      labelLarge:     _inter(size: 14, weight: FontWeight.w600),
      labelMedium:    _inter(size: 12, color: AppColors.textSecondary),
      labelSmall:     _inter(size: 11, color: AppColors.textSecondary),
    ),

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: _inter(size: 17, weight: FontWeight.w700),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // ── Bottom navigation ─────────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),

    // ── FAB ──────────────────────────────────────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.fabBg,
      foregroundColor: AppColors.fabIcon,
      shape: CircleBorder(),
      elevation: 4,
    ),

    // ── Buttons ───────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: _inter(size: 16, weight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _inter(size: 15, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: _inter(size: 14, weight: FontWeight.w500, color: AppColors.accent),
      ),
    ),

    // ── Inputs ────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surface3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x38FF9100)), // rgba(255,145,0,.22)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: _inter(size: 14, color: AppColors.textSecondary),
      hintStyle: _inter(size: 14, color: AppColors.textSecondary),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      errorStyle: _inter(size: 12, color: AppColors.error),
    ),

    // ── Cards ─────────────────────────────────────────────────────────────────
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: AppColors.borderSoft, width: 1),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.surface3,
      thickness: 1,
      space: 1,
    ),

    // ── Chips ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.primary,
      disabledColor: AppColors.surface2,
      labelStyle: _inter(size: 12, color: AppColors.textSecondary),
      side: const BorderSide(color: Color(0x2BFF9100)), // rgba(255,145,0,.17)
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: _inter(size: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),

    // ── Switch ───────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : Colors.grey.shade600),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.surface3),
    ),

    // ── Checkbox ─────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.surface3, width: 1.5),
    ),

    // ── Icons ─────────────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    primaryIconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}

extension RouterContextX on BuildContext {
  bool get isCoach {
    final container = ProviderScope.containerOf(this);
    final user = container.read(currentUserModelProvider).value;
    return user?.isCoach ?? false;
  }

  UserModel? get currentUser {
    final container = ProviderScope.containerOf(this);
    return container.read(currentUserModelProvider).value;
  }
}
