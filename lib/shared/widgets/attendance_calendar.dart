import 'package:flutter/material.dart';
import '../../core/models/attendance_model.dart';

/// A seasonal attendance calendar showing Sep→Jul.
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.trainingDates,
    required this.absenceMap,
    required this.seasonYear,
  });

  /// All training dates in the season.
  final List<DateTime> trainingDates;

  /// "YYYY-MM-DD" → false (absent). Missing key = present on a training day.
  final Map<String, bool> absenceMap;

  /// e.g. 2024 means Sep 2024 → Jul 2025.
  final int seasonYear;

  static const _monthNames = [
    'Вересень',
    'Жовтень',
    'Листопад',
    'Грудень',
    'Січень',
    'Лютий',
    'Березень',
    'Квітень',
    'Травень',
    'Червень',
    'Липень',
  ];

  static const _dayHeaders = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  // Months: Sep(9)..Dec(12) of seasonYear, Jan(1)..Jul(7) of seasonYear+1
  List<({int year, int month})> get _months {
    final list = <({int year, int month})>[];
    for (var m = 9; m <= 12; m++) {
      list.add((year: seasonYear, month: m));
    }
    for (var m = 1; m <= 7; m++) {
      list.add((year: seasonYear + 1, month: m));
    }
    return list;
  }

  Set<String> get _trainingDateSet {
    return trainingDates
        .map((d) => AttendanceModel.dateKey(d))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final trainingSet = _trainingDateSet;
    final today = DateTime.now();
    final todayKey = AttendanceModel.dateKey(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _months.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        return _MonthGrid(
          year: m.year,
          month: m.month,
          monthName: '${_monthNames[idx]} ${m.year}',
          dayHeaders: _dayHeaders,
          trainingSet: trainingSet,
          absenceMap: absenceMap,
          todayKey: todayKey,
        );
      }).toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.monthName,
    required this.dayHeaders,
    required this.trainingSet,
    required this.absenceMap,
    required this.todayKey,
  });

  final int year;
  final int month;
  final String monthName;
  final List<String> dayHeaders;
  final Set<String> trainingSet;
  final Map<String, bool> absenceMap;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // weekday of day 1: 1=Mon … 7=Sun
    final firstWeekday = DateTime(year, month, 1).weekday;

    // Total cells: leading blanks + days
    final totalCells = (firstWeekday - 1) + daysInMonth;
    // Rows needed (ceil to next multiple of 7)
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              monthName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Day-of-week header
          Row(
            children: dayHeaders
                .map((h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Day grid
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - (firstWeekday - 1) + 1;

                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 30));
                }

                final dateKey = AttendanceModel.dateKey(
                    DateTime(year, month, dayNum));
                final isTraining = trainingSet.contains(dateKey);
                final isAbsent = absenceMap[dateKey] == false;
                final isToday = dateKey == todayKey;

                return Expanded(
                  child: _DayCell(
                    day: dayNum,
                    isTraining: isTraining,
                    isAbsent: isAbsent,
                    isToday: isToday,
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isTraining,
    required this.isAbsent,
    required this.isToday,
  });

  final int day;
  final bool isTraining;
  final bool isAbsent;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = Colors.grey.shade500;
    Border? border;

    if (isTraining) {
      if (isAbsent) {
        bgColor = Colors.red.shade400;
        textColor = Colors.white;
      } else {
        bgColor = Colors.green.shade400;
        textColor = Colors.white;
      }
    }

    if (isToday) {
      border = Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 1.5,
      );
    }

    return Container(
      height: 30,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 11,
            color: isTraining ? textColor : Colors.grey.shade500,
            fontWeight: isTraining ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
