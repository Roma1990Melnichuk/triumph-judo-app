import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/questionnaire_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/questionnaire_provider.dart';

class AnswerQuestionnaireScreen extends ConsumerStatefulWidget {
  const AnswerQuestionnaireScreen({
    super.key,
    required this.questionnaireId,
    required this.childId,
  });

  final String questionnaireId;
  final String childId;

  @override
  ConsumerState<AnswerQuestionnaireScreen> createState() =>
      _AnswerQuestionnaireScreenState();
}

class _AnswerQuestionnaireScreenState
    extends ConsumerState<AnswerQuestionnaireScreen> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _textCtrls = {};
  bool _submitted = false;
  bool _saving    = false;

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(QuestionnaireModel q) async {
    final answers = <QuestionAnswer>[];
    for (final qd in q.questions) {
      final val = _answers[qd.id];
      answers.add(QuestionAnswer(
        questionId: qd.id,
        textValue:  qd.type == QuestionType.text  ? val as String? : null,
        boolValue:  qd.type == QuestionType.yesNo ? val as bool?   : null,
        scaleValue: qd.type == QuestionType.scale ? val as int?    : null,
      ));
    }

    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserModelProvider).asData?.value;
      await ref.read(questionnaireNotifierProvider.notifier).submitResponse(
            questionnaireId: widget.questionnaireId,
            childId:         widget.childId,
            childName:       user?.name ?? '',
            answers:         answers,
          );
      if (mounted) setState(() { _submitted = true; _saving = false; });
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
    final questAsync = ref.watch(questionnairesProvider);
    final q = questAsync.asData?.value
        .where((q) => q.id == widget.questionnaireId)
        .firstOrNull;

    if (q == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_submitted) return _SuccessScreen(onDone: () => context.pop());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(q.title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (q.description.isNotEmpty) ...[
            Text(q.description,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
          ],
          ...List.generate(q.questions.length, (i) {
            final qd = q.questions[i];
            return _QuestionWidget(
              index: i + 1,
              qd:    qd,
              value: _answers[qd.id],
              textCtrl: _textCtrls.putIfAbsent(
                  qd.id, () => TextEditingController()),
              onChanged: (v) => setState(() => _answers[qd.id] = v),
            );
          }),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: _saving ? null : () => _submit(q),
            isLoading: _saving,
            child: const Text('Надіслати відповідь',
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

class _QuestionWidget extends StatelessWidget {
  const _QuestionWidget({
    required this.index,
    required this.qd,
    required this.value,
    required this.textCtrl,
    required this.onChanged,
  });

  final int                        index;
  final QuestionDef                qd;
  final dynamic                    value;
  final TextEditingController      textCtrl;
  final ValueChanged<dynamic>      onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index. ${qd.text}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (qd.type == QuestionType.text)
            TextField(
              controller: textCtrl,
              onChanged: onChanged,
              decoration: const InputDecoration(
                  hintText: 'Ваша відповідь...',
                  border: OutlineInputBorder()),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            )
          else if (qd.type == QuestionType.yesNo)
            Row(
              children: [
                _YesNoBtn(
                    label: 'Так', active: value == true,
                    onTap: () => onChanged(true)),
                const SizedBox(width: 10),
                _YesNoBtn(
                    label: 'Ні', active: value == false,
                    onTap: () => onChanged(false)),
              ],
            )
          else // scale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final n      = i + 1;
                final active = value == n;
                return GestureDetector(
                  onTap: () => onChanged(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.orange
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.orange
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.black : AppColors.textSecondary,
                          )),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _YesNoBtn extends StatelessWidget {
  const _YesNoBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String       label;
  final bool         active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.orange : const Color(0xFF2C2C2C),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.orange : AppColors.textSecondary,
            )),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                    color: Color(0xFF0D2A1A), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Дякуємо за відповідь!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 10),
              const Text(
                'Тренер отримає ваші відповіді і врахує їх у роботі.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GradientButton(
                onPressed: onDone,
                child: const Text('Закрити',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
