import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/club_honor_board_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/stream_utils.dart';

// ── Stream ────────────────────────────────────────────────────────────────────

final honorBoardProvider = StreamProvider<List<ClubHonorBoardItem>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('honor_board')
      .where('isVisible', isEqualTo: true)
      .orderBy('isPinned', descending: true)
      .orderBy('publishedAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ClubHonorBoardItem.fromFirestore).toList())
      .fallbackOnError(const []);
});

// Filter state: null = all, true = medals, false = belt, string = progress
enum HonorBoardFilter { all, medals, belts, progress }

extension HonorBoardFilterX on HonorBoardFilter {
  String get label => switch (this) {
        HonorBoardFilter.all      => 'Всі',
        HonorBoardFilter.medals   => 'Медалі',
        HonorBoardFilter.belts    => 'Пояси',
        HonorBoardFilter.progress => 'Прогрес',
      };
}

final honorBoardFilterProvider =
    StateProvider<HonorBoardFilter>((ref) => HonorBoardFilter.all);

final filteredHonorBoardProvider =
    Provider<List<ClubHonorBoardItem>>((ref) {
  final items = ref.watch(honorBoardProvider).asData?.value ?? [];
  final filter = ref.watch(honorBoardFilterProvider);
  return switch (filter) {
    HonorBoardFilter.all      => items,
    HonorBoardFilter.medals   => items.where((i) => i.type.isMedal).toList(),
    HonorBoardFilter.belts    => items.where((i) => i.type.isBelt).toList(),
    HonorBoardFilter.progress => items.where((i) => i.type.isProgress).toList(),
  };
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class HonorBoardNotifier extends StateNotifier<AsyncValue<void>> {
  HonorBoardNotifier(this._db) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Future<void> addItem(ClubHonorBoardItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = _uuid.v4();
      await _db.collection('honor_board').doc(id).set(item.toFirestore());
    });
  }

  Future<void> updateItem(ClubHonorBoardItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('honor_board').doc(item.id).update(item.toFirestore());
    });
  }

  Future<void> deleteItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _db.collection('honor_board').doc(id).delete();
    });
  }

  Future<void> toggleVisibility(String id, bool current) async {
    await _db.collection('honor_board').doc(id).update({'isVisible': !current});
  }

  Future<void> togglePin(String id, bool current) async {
    await _db.collection('honor_board').doc(id).update({'isPinned': !current});
  }
}

final honorBoardNotifierProvider =
    StateNotifierProvider<HonorBoardNotifier, AsyncValue<void>>(
  (ref) => HonorBoardNotifier(ref.watch(firestoreProvider)),
);
