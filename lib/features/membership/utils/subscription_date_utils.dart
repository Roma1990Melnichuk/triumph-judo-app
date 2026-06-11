/// Pure date helpers for subscription lifecycle.
/// Extracted here so they can be unit-tested independently of the UI.

/// Calculates the end date of a new subscription.
DateTime computeSubscriptionEndDate(
  String planName,
  int multiplier,
  DateTime start,
) {
  if (planName.contains('Разове')) {
    return start.add(Duration(days: multiplier));
  }
  if (planName.contains('тиждень')) {
    return start.add(Duration(days: 7 * multiplier));
  }
  final monthMatch = RegExp(r'(\d+)\s*місяц').firstMatch(planName);
  if (monthMatch != null) {
    final months = int.parse(monthMatch.group(1)!) * multiplier;
    return DateTime(start.year, start.month + months, start.day);
  }
  return DateTime(start.year, start.month + multiplier, start.day);
}

/// FIN-01: returns the start date for a new subscription.
/// If the athlete already has an active membership, extends from its end so
/// no days are lost.
DateTime resolveSubscriptionStart({
  required DateTime now,
  required bool isCurrentlyActive,
  required DateTime? currentEndDate,
}) {
  return (isCurrentlyActive && currentEndDate != null) ? currentEndDate : now;
}
