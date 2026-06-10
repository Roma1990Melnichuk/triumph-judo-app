import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/journey_messages.dart';
import '../../../core/models/training_session_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../team/providers/children_provider.dart';

// ── DateTime extension ────────────────────────────────────────────────────────

extension DateTimeJourney on DateTime {
  /// Day-of-year: 1-based (1 Jan = 1, 31 Dec = 365 or 366).
  int get dayOfYear => difference(DateTime(year)).inDays + 1;

  /// Returns true if this date falls on the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

// ── Streak data record ────────────────────────────────────────────────────────

typedef StreakData = ({int current, int best, int total});

// ── Internal helper: resolve active childId and coachId for current user ──────

/// Returns (childId, coachId) or null if the current user is a coach or
/// has no linked child.
({String childId, String coachId})? _resolveChild(Ref ref) {
  final user = ref.watch(currentUserModelProvider).value;
  if (user == null || user.isCoach) return null;

  final childId = user.childIds.firstOrNull ?? user.childId;
  if (childId == null || childId.isEmpty) return null;

  final allChildren = ref.watch(allChildrenProvider).value ?? [];
  final child = allChildren.where((c) => c.id == childId).firstOrNull;
  if (child == null) return null;

  return (childId: childId, coachId: child.coachId);
}

// ── streakDataProvider ────────────────────────────────────────────────────────

/// Computes streak statistics for the currently-logged-in athlete.
/// Returns (current: 0, best: 0, total: 0) for coaches or when data is missing.
final streakDataProvider = Provider<StreakData>((ref) {
  const empty = (current: 0, best: 0, total: 0);

  final resolved = _resolveChild(ref);
  if (resolved == null) return empty;

  final childId = resolved.childId;
  final coachId = resolved.coachId;

  final sessionsAsync = ref.watch(coachSessionsProvider(coachId));
  final sessions = sessionsAsync.value;
  if (sessions == null) return empty;

  // sessions are already sorted date DESC (most recent first)
  int current = 0;
  int best = 0;
  int running = 0;
  int total = 0;
  bool streakBroken = false;

  for (final session in sessions) {
    final present = session.isPresent(childId);
    if (present) {
      total++;
      if (!streakBroken) current++;
      running++;
      if (running > best) best = running;
    } else {
      streakBroken = true;
      running = 0;
    }
  }

  return (current: current, best: best, total: total);
});

// ── dailyMessageProvider ──────────────────────────────────────────────────────

/// Returns today's motivational message, rotated daily.
final dailyMessageProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return kJourneyMessages[now.dayOfYear % kJourneyMessages.length];
});

// ── weekActivityProvider ──────────────────────────────────────────────────────

/// Returns 7 bools [Mon, Tue, Wed, Thu, Fri, Sat, Sun] for the current week.
/// true  = athlete was present at a session on that calendar day.
/// false = no session or athlete was absent.
final weekActivityProvider = Provider<List<bool>>((ref) {
  final resolved = _resolveChild(ref);
  if (resolved == null) return List.filled(7, false);

  final childId = resolved.childId;
  final coachId = resolved.coachId;

  final sessions = ref.watch(coachSessionsProvider(coachId)).value ?? [];

  // Build Mon-Sun range for the current week.
  final now = DateTime.now();
  // weekday: Mon=1 … Sun=7
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));

  final List<bool> result = [];
  for (var i = 0; i < 7; i++) {
    final day = monday.add(Duration(days: i));
    final trained = sessions.any(
      (s) => s.date.isSameDay(day) && s.isPresent(childId),
    );
    result.add(trained);
  }
  return result;
});

// ── fourWeekActivityProvider ──────────────────────────────────────────────────

/// Returns a flat list of (date, bool) for the last 4 complete weeks
/// (Mon of 4 weeks ago → Sun of current week, 28 days total).
/// bool = athlete trained on that day.
final fourWeekActivityProvider =
    Provider<List<({DateTime date, bool trained, bool future})>>((ref) {
  final resolved = _resolveChild(ref);
  final childId = resolved?.childId ?? '';
  final coachId = resolved?.coachId ?? '';

  final sessions = coachId.isEmpty
      ? <TrainingSessionModel>[]
      : (ref.watch(coachSessionsProvider(coachId)).value ?? []);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Start from Monday 3 weeks ago
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final start = monday.subtract(const Duration(days: 21));

  final List<({DateTime date, bool trained, bool future})> result = [];
  for (var i = 0; i < 28; i++) {
    final day = start.add(Duration(days: i));
    final isFuture = day.isAfter(today);
    final trained = !isFuture &&
        childId.isNotEmpty &&
        sessions.any((s) => s.date.isSameDay(day) && s.isPresent(childId));
    result.add((date: day, trained: trained, future: isFuture));
  }
  return result;
});
