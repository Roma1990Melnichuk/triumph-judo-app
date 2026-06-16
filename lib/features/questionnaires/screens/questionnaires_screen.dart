import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../core/models/questionnaire_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/questionnaire_provider.dart';

class QuestionnairesScreen extends ConsumerWidget {
  const QuestionnairesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(currentUserModelProvider).asData?.value;
    final isCoach = user?.isCoach ?? false;

    if (isCoach) return const _CoachView();
    return _ParentView(childId: user?.childId ??
        (user?.childIds.isNotEmpty == true ? user!.childIds.first : ''));
  }
}

// ── Coach view ────────────────────────────────────────────────────────────────

class _CoachView extends ConsumerWidget {
  const _CoachView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(questionnairesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Опитування',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.orange),
                onPressed: () => context.push('/questionnaires/create'),
              ),
            ],
          ),
          questAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Помилка: $e'))),
            data: (list) {
              if (list.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(isCoach: true),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _CoachQuestionnaireCard(q: list[i]),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoachQuestionnaireCard extends ConsumerWidget {
  const _CoachQuestionnaireCard({required this.q});
  final QuestionnaireModel q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsesAsync = ref.watch(questionnaireResponsesProvider(q.id));
    final count = responsesAsync.asData?.value.length ?? 0;

    return GestureDetector(
      onTap: () => context.push('/questionnaires/${q.id}/results'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: q.isActive
                ? AppColors.orange.withValues(alpha: 0.3)
                : const Color(0xFF222222),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(q.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                _StatusChip(active: q.isActive),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(questionnaireNotifierProvider.notifier)
                      .toggleActive(q),
                  child: Icon(
                    q.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            if (q.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(q.description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.help_outline_rounded,
                    label: '${q.questions.length} питань'),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.people_outline_rounded,
                    label: '$count відповідей'),
                const Spacer(),
                Text(
                  DateFormat('d MMM', 'uk').format(q.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Parent view ───────────────────────────────────────────────────────────────

class _ParentView extends ConsumerWidget {
  const _ParentView({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync    = ref.watch(activeQuestionnairesProvider);
    final myResponsesAsync = ref.watch(childResponsesProvider(childId));
    final myResponseIds = myResponsesAsync.asData?.value
        .map((r) => r.questionnaireId)
        .toSet() ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: AppBackButton(onPressed: () => context.pop()),
            title: const Text('Опитування',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          activeAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Помилка: $e'))),
            data: (list) {
              if (list.isEmpty) {
                return const SliverFillRemaining(
                    child: _EmptyState(isCoach: false));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final q       = list[i];
                      final done    = myResponseIds.contains(q.id);
                      return _ParentQuestionnaireCard(
                        q:       q,
                        childId: childId,
                        done:    done,
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ParentQuestionnaireCard extends StatelessWidget {
  const _ParentQuestionnaireCard({
    required this.q,
    required this.childId,
    required this.done,
  });

  final QuestionnaireModel q;
  final String             childId;
  final bool               done;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: done
          ? null
          : () => context.push('/questionnaires/${q.id}/answer',
              extra: {'childId': childId}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (done ? AppColors.success : AppColors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.quiz_outlined,
                color: done ? AppColors.success : AppColors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    done
                        ? 'Вже відповіли'
                        : '${q.questions.length} питань — натисніть, щоб відповісти',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            done ? AppColors.success : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!done)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? AppColors.success : AppColors.textSecondary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Активне' : 'Закрите',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isCoach});
  final bool isCoach;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            isCoach ? 'Опитувань ще немає' : 'Активних опитувань немає',
            style: const TextStyle(
                fontSize: 16, color: AppColors.textSecondary),
          ),
          if (isCoach) ...[
            const SizedBox(height: 8),
            const Text(
              'Натисніть + щоб створити перше опитування',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
