import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/questionnaire_model.dart';
import '../providers/questionnaire_provider.dart';

class QuestionnaireResultsScreen extends ConsumerWidget {
  const QuestionnaireResultsScreen({super.key, required this.questionnaireId});
  final String questionnaireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync     = ref.watch(questionnairesProvider);
    final responsesAsync = ref.watch(questionnaireResponsesProvider(questionnaireId));

    final q = questAsync.asData?.value
        .where((q) => q.id == questionnaireId)
        .firstOrNull;

    final responses = responsesAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(q?.title ?? 'Результати',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          if (q != null)
            SliverToBoxAdapter(
              child: _SummaryBar(q: q, count: responses.length),
            ),
          if (responses.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('Відповідей ще немає',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ResponseCard(
                    response: responses[i],
                    questions: q?.questions ?? [],
                  ),
                  childCount: responses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.q, required this.count});
  final QuestionnaireModel q;
  final int                count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count відповідей отримано',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('${q.questions.length} питань · '
                      '${DateFormat("d MMM", "uk").format(q.createdAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response, required this.questions});
  final QuestionnaireResponseModel response;
  final List<QuestionDef>          questions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: CircleAvatar(
            backgroundColor: AppColors.orange.withValues(alpha: 0.15),
            child: Text(
              response.childName.isNotEmpty
                  ? response.childName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            response.childName.isNotEmpty
                ? response.childName
                : 'Анонімно',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          subtitle: Text(
            DateFormat('d MMM yyyy, HH:mm', 'uk')
                .format(response.submittedAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          children: response.answers.map((a) {
            final qd = questions
                .where((q) => q.id == a.questionId)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(qd?.text ?? a.questionId,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Text(a.displayValue,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const Divider(color: Color(0xFF222222), height: 16),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
