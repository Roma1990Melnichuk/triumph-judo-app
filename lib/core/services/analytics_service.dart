import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralised analytics event logging.
/// All key product actions are tracked here so the PM can measure
/// activation, engagement and retention in Firebase Analytics / GA4.
class AnalyticsService {
  static final _a = FirebaseAnalytics.instance;

  // ── Activation ──────────────────────────────────────────────────────────────
  static Future<void> childAdded()   => _a.logEvent(name: 'child_added');
  static Future<void> childUpdated() => _a.logEvent(name: 'child_updated');
  static Future<void> childDeleted() => _a.logEvent(name: 'child_deleted');

  // ── Belt progress ───────────────────────────────────────────────────────────
  static Future<void> exerciseToggled({required String belt, required bool passed}) =>
      _a.logEvent(name: 'exercise_toggled', parameters: {
        'belt': belt,
        'passed': passed ? 1 : 0,
      });

  static Future<void> allExercisesApproved({required String belt}) =>
      _a.logEvent(name: 'all_exercises_approved', parameters: {'belt': belt});

  static Future<void> beltReadyAchieved({required String belt}) =>
      _a.logEvent(name: 'belt_ready_achieved', parameters: {'belt': belt});

  // ── Competition results ─────────────────────────────────────────────────────
  static Future<void> resultAdded({required String level, required int place}) =>
      _a.logEvent(name: 'result_added', parameters: {
        'level': level,
        'place': place,
      });

  static Future<void> resultDeleted() => _a.logEvent(name: 'result_deleted');

  // ── Filters (engagement depth) ──────────────────────────────────────────────
  static Future<void> filterApplied({required String filterName}) =>
      _a.logEvent(name: 'filter_applied', parameters: {'filter': filterName});

  static Future<void> filterCleared({required String filterName}) =>
      _a.logEvent(name: 'filter_cleared', parameters: {'filter': filterName});

  // ── Parent linking ──────────────────────────────────────────────────────────
  static Future<void> childLinked()   => _a.logEvent(name: 'child_linked');
  static Future<void> childUnlinked() => _a.logEvent(name: 'child_unlinked');

  // ── Auth ────────────────────────────────────────────────────────────────────
  static Future<void> coachPromoted() => _a.logEvent(name: 'coach_promoted');
  static Future<void> signedOut()     => _a.logEvent(name: 'signed_out');

  // ── Season management ───────────────────────────────────────────────────────
  static Future<void> seasonReset({required int year}) =>
      _a.logEvent(name: 'season_reset', parameters: {'year': year});

  // ── Screen view helper ──────────────────────────────────────────────────────
  static Future<void> screen(String name) =>
      _a.logScreenView(screenName: name);
}
