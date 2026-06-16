import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/questionnaire_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/questionnaire_provider.dart';

class CreateQuestionnaireScreen extends ConsumerStatefulWidget {
  const CreateQuestionnaireScreen({super.key});

  @override
  ConsumerState<CreateQuestionnaireScreen> createState() =>
      _CreateQuestionnaireScreenState();
}

class _CreateQuestionnaireScreenState
    extends ConsumerState<CreateQuestionnaireScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final List<_EditableQuestion> _questions = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final q in _questions) {
      q.ctrl.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_EditableQuestion()));
  }

  void _removeQuestion(int i) {
    setState(() {
      _questions[i].ctrl.dispose();
      _questions.removeAt(i);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введіть назву опитування')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Додайте хоча б одне питання')));
      return;
    }
    final questions = _questions
        .where((q) => q.ctrl.text.trim().isNotEmpty)
        .map((q) => QuestionDef(
              id:   DateTime.now().microsecondsSinceEpoch.toString() +
                    _questions.indexOf(q).toString(),
              text: q.ctrl.text.trim(),
              type: q.type,
            ))
        .toList();
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заповніть текст питань')));
      return;
    }
    setState(() => _saving = true);
    try {
      final coachId =
          ref.read(currentUserModelProvider).asData?.value?.uid ?? '';
      await ref.read(questionnaireNotifierProvider.notifier).createQuestionnaire(
            title:       title,
            description: _descCtrl.text.trim(),
            questions:   questions,
            coachId:     coachId,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Помилка: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Нове опитування',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        leading: AppBackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Title
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                labelText: 'Назва опитування *',
                prefixIcon: Icon(Icons.quiz_outlined)),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          // Description
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Опис (необов\'язково)',
                prefixIcon: Icon(Icons.description_outlined)),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Questions
          Row(
            children: [
              const Text('Питання',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: _addQuestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          color: AppColors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('Додати питання',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF2A2A2A),
                    style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('Натисніть «Додати питання»',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ),

          ...List.generate(_questions.length, (i) {
            final eq = _questions[i];
            return _QuestionEditor(
              index:    i + 1,
              eq:       eq,
              onRemove: () => _removeQuestion(i),
              onTypeChanged: (t) =>
                  setState(() => eq.type = t),
            );
          }),

          const SizedBox(height: 24),
          GradientButton(
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            child: const Text('Зберегти опитування',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _EditableQuestion {
  final TextEditingController ctrl = TextEditingController();
  QuestionType type = QuestionType.text;
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.index,
    required this.eq,
    required this.onRemove,
    required this.onTypeChanged,
  });

  final int              index;
  final _EditableQuestion eq;
  final VoidCallback     onRemove;
  final ValueChanged<QuestionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Питання $index',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange)),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: eq.ctrl,
            decoration: const InputDecoration(
                hintText: 'Текст питання...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QuestionType.values.map((t) {
                final active = eq.type == t;
                return GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.orange.withValues(alpha: 0.18)
                          : const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppColors.orange
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppColors.orange
                              : AppColors.textSecondary,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
