import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/belt_levels.dart';
import '../core/models/child_model.dart';
import '../core/models/competition_result_model.dart';
import '../core/models/individual_slot_model.dart';

class ExportService {
  static final _dateFmt = DateFormat('dd.MM.yyyy');
  static final _fileDate = DateFormat('yyyy-MM-dd');

  // ── Export athletes list ───────────────────────────────────────────────────
  static Future<void> exportAthletes(
    BuildContext context,
    List<ChildModel> children,
  ) async {
    final rows = <List<dynamic>>[
      ['#', 'Прізвище', "Ім'я", 'Рік нар.', 'Пояс', 'Стать', 'Вага', 'Тренер', 'Бали'],
    ];
    for (var i = 0; i < children.length; i++) {
      final c = children[i];
      rows.add([
        i + 1,
        c.lastName,
        c.firstName,
        c.birthYear,
        c.currentBelt.displayName,
        c.gender?.displayName ?? '—',
        displayWeight(c.weightCategory),
        c.coachName,
        c.totalPoints,
      ]);
    }
    await _saveFile(context, rows, 'команда_${_today()}.csv');
  }

  // ── Export competition results ────────────────────────────────────────────
  static Future<void> exportResults(
    BuildContext context,
    List<CompetitionResultModel> results,
  ) async {
    final rows = <List<dynamic>>[
      ['#', 'Спортсмен', 'Змагання', 'Тип', 'Рівень', 'Місце', 'Бали', 'Дата'],
    ];
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      rows.add([
        i + 1,
        r.childName,
        r.competitionName,
        r.competitionType,
        r.level.displayName,
        r.place,
        r.points,
        _dateFmt.format(r.date),
      ]);
    }
    await _saveFile(context, rows, 'результати_${_today()}.csv');
  }

  // ── Export individual training sessions ───────────────────────────────────
  static Future<void> exportIndividualTrainings(
    BuildContext context,
    List<IndividualSlotModel> slots,
  ) async {
    final rows = <List<dynamic>>[
      ['#', 'Дата', 'Початок', 'Кінець', 'Спортсмен', 'Статус', 'Ціна', 'Оплачено'],
    ];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      rows.add([
        i + 1,
        _dateFmt.format(s.date),
        s.timeStart,
        s.timeEnd,
        s.childName ?? '—',
        s.status.displayName,
        s.price != null ? '${s.price} ${s.currency}' : '—',
        s.isPaid ? 'Так' : 'Ні',
      ]);
    }
    await _saveFile(context, rows, 'індив_тренування_${_today()}.csv');
  }

  // ── Internal: convert to CSV and open save dialog ─────────────────────────
  static Future<void> _saveFile(
    BuildContext context,
    List<List<dynamic>> rows,
    String defaultName,
  ) async {
    // BOM + CSV for correct Excel UTF-8 encoding
    final csv = const ListToCsvConverter().convert(rows);
    final content = '﻿$csv';
    final bytes = Uint8List.fromList(content.codeUnits);

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Зберегти файл',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Збережено: $path')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка експорту: $e')),
        );
      }
    }
  }

  static String _today() => _fileDate.format(DateTime.now());
}
