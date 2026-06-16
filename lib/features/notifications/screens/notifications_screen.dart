import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/belt_levels.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../team/providers/children_provider.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';

final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Widget _backButton(BuildContext context) =>
      AppBackButton(onPressed: () => context.pop());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final isCoach = user?.isCoach ?? false;

    if (isCoach) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
                  child: Row(
                    children: [
                      _backButton(context),
                      const SizedBox(width: 16),
                      const Text(
                        'Сповіщення',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  tabs: [
                    Tab(text: 'Сповіщення'),
                    Tab(text: 'Від батьків'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [_CoachBody(), _CoachMessagesBody()],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (user != null) {
                showDialog<void>(
                  context: context,
                  builder: (_) => _ComposeDialog(
                    coachId: user.uid,
                    coachName: user.name,
                  ),
                );
              }
            },
            child: const Icon(Icons.edit_outlined),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
              child: Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 16),
                  const Text(
                    'Сповіщення',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: _ParentBody()),
          ],
        ),
      ),
      floatingActionButton: user != null
          ? FloatingActionButton(
              backgroundColor: AppColors.surface2,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ParentComposeDialog(user: user),
              ),
              child: const Icon(Icons.chat_outlined, color: AppColors.accent),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach body — list of all sent notifications
// ─────────────────────────────────────────────────────────────────────────────

class _CoachBody extends ConsumerWidget {
  const _CoachBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(allNotificationsProvider);

    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Помилка: $e')),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: AppColors.surface3),
                SizedBox(height: 12),
                Text('Немає надісланих сповіщень',
                    style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 4),
                Text('Натисніть + щоб надіслати',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, i) =>
              _CoachNotifTile(notif: notifications[i]),
        );
      },
    );
  }
}

class _CoachNotifTile extends ConsumerWidget {
  const _CoachNotifTile({required this.notif});
  final NotificationModel notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(notif.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Видалити сповіщення?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Скасувати'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Видалити'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                ref
                    .read(notificationsNotifierProvider.notifier)
                    .delete(notif.id);
              }
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Видалити',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: _NotifCard(notif: notif, isCoach: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent/athlete body — filtered relevant notifications
// ─────────────────────────────────────────────────────────────────────────────

class _ParentBody extends ConsumerWidget {
  const _ParentBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final notificationsValue = ref.watch(myNotificationsProvider);

    return notificationsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Помилка: $e')),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: AppColors.surface3),
                SizedBox(height: 12),
                Text('Немає сповіщень',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, i) {
            final notif = notifications[i];
            final uid = user?.uid ?? '';
            final isRead = uid.isNotEmpty && notif.readByUserIds.contains(uid);
            return _ParentNotifTile(
                notif: notif, isRead: isRead, uid: uid);
          },
        );
      },
    );
  }
}

class _ParentNotifTile extends ConsumerWidget {
  const _ParentNotifTile({
    required this.notif,
    required this.isRead,
    required this.uid,
  });
  final NotificationModel notif;
  final bool isRead;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NotifCard(
      notif: notif,
      isCoach: false,
      isRead: isRead,
      onTap: () {
        if (!isRead && uid.isNotEmpty) {
          ref
              .read(notificationsNotifierProvider.notifier)
              .markRead(notif.id, uid);
        }
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(notif.title),
            content: SingleChildScrollView(child: Text(notif.body)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared notification card
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.notif,
    required this.isCoach,
    this.isRead = true,
    this.onTap,
  });
  final NotificationModel notif;
  final bool isCoach;
  final bool isRead;
  final VoidCallback? onTap;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _targetLabel {
    switch (notif.target) {
      case NotificationTarget.all:
        return 'Всім';
      case NotificationTarget.ageGroup:
        return 'Вік: ${notif.targetValues.join(', ')}';
      case NotificationTarget.belt:
        return 'Пояси: ${notif.targetValues.map((v) => BeltLevelX.fromString(v).displayName).join(', ')}';
      case NotificationTarget.top20age:
        return 'Топ 20 (${notif.targetValues.firstOrNull ?? ''} р.н.)';
      case NotificationTarget.exceptTop20age:
        return 'Крім топ 20 (${notif.targetValues.firstOrNull ?? ''} р.н.)';
      case NotificationTarget.personal:
        return 'Особисте';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !isRead
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.surface3,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(notif.coachName),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            if (notif.coachName.isNotEmpty)
              Text(
                notif.coachName,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 2),
            Text(
              notif.body,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  child: Text(
                    _targetLabel,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  _dateFmt.format(notif.sentAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: !isRead && !isCoach
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach: messages from parents
// ─────────────────────────────────────────────────────────────────────────────

class _CoachMessagesBody extends ConsumerWidget {
  const _CoachMessagesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(parentMessagesProvider);
    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Помилка: $e')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: AppColors.surface3),
                SizedBox(height: 12),
                Text('Немає повідомлень від батьків',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, i) =>
              _ParentMessageTile(msg: messages[i]),
        );
      },
    );
  }
}

class _ParentMessageTile extends ConsumerWidget {
  const _ParentMessageTile({required this.msg});
  final ParentMessageModel msg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !msg.readByCoach
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.surface3,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.surface2,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person_outline,
              color: AppColors.textSecondary),
        ),
        title: Text(
          msg.fromParentName.isNotEmpty ? msg.fromParentName : 'Батько/Мати',
          style: TextStyle(
            fontWeight:
                msg.readByCoach ? FontWeight.w500 : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(msg.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              _dateFmt.format(msg.sentAt),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: !msg.readByCoach
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!msg.readByCoach) {
            ref.read(messageNotifierProvider.notifier).markRead(msg.id);
          }
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(msg.fromParentName.isNotEmpty
                  ? msg.fromParentName
                  : 'Батько/Мати'),
              content:
                  SingleChildScrollView(child: Text(msg.body)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent compose dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ParentComposeDialog extends ConsumerStatefulWidget {
  const _ParentComposeDialog({required this.user});
  final UserModel user;

  @override
  ConsumerState<_ParentComposeDialog> createState() =>
      _ParentComposeDialogState();
}

class _ParentComposeDialogState
    extends ConsumerState<_ParentComposeDialog> {
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String toCoachId) async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(messageNotifierProvider.notifier).send(
            fromParentId: widget.user.uid,
            fromParentName: widget.user.name,
            toCoachId: toCoachId,
            body: body,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children =
        ref.watch(allChildrenProvider).asData?.value ?? [];
    final childId =
        widget.user.childIds.firstOrNull ?? widget.user.childId;
    final child =
        children.where((c) => c.id == childId).firstOrNull;
    final coachId = child?.coachId ?? '';
    final coachName = child?.coachName ?? 'Тренер';

    return AlertDialog(
      title: const Text('Написати тренеру'),
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: 300, minWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Кому: $coachName',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Повідомлення'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _loading ? null : () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed:
              (_loading || coachId.isEmpty) ? null : () => _send(coachId),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Надіслати',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compose dialog (AlertDialog — avoids Cyrillic IME issues on Android BottomSheet)
// ─────────────────────────────────────────────────────────────────────────────

class _ComposeDialog extends ConsumerStatefulWidget {
  const _ComposeDialog({required this.coachId, required this.coachName});
  final String coachId;
  final String coachName;

  @override
  ConsumerState<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends ConsumerState<_ComposeDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  NotificationTarget _target = NotificationTarget.all;
  final Set<String> _selectedValues = {};
  String? _top20Year;
  bool _loading = false;

  // Populated each build from allChildrenProvider
  List<int> _availableYears = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    List<String> targetValues;
    switch (_target) {
      case NotificationTarget.all:
      case NotificationTarget.personal:
        targetValues = [];
      case NotificationTarget.ageGroup:
      case NotificationTarget.belt:
        if (_selectedValues.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оберіть хоча б одне значення')),
          );
          return;
        }
        targetValues = _selectedValues.toList();
      case NotificationTarget.top20age:
      case NotificationTarget.exceptTop20age:
        final year = _top20Year ??
            (_availableYears.isNotEmpty
                ? _availableYears.first.toString()
                : null);
        if (year == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Немає доступних років')),
          );
          return;
        }
        targetValues = [year];
    }

    setState(() => _loading = true);
    try {
      final notification = NotificationModel(
        id: '',
        title: title,
        body: body,
        target: _target,
        targetValues: targetValues,
        sentAt: DateTime.now(),
        coachId: widget.coachId,
        coachName: widget.coachName,
        readByUserIds: const [],
      );
      await ref
          .read(notificationsNotifierProvider.notifier)
          .send(notification);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).asData?.value ?? [];
    _availableYears = children
        .map((c) => c.birthYear)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final effectiveTop20Year = _top20Year ??
        (_availableYears.isNotEmpty ? _availableYears.first.toString() : null);

    return AlertDialog(
      title: const Text('Нове повідомлення'),
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: 480, minWidth: 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(labelText: 'Заголовок'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Текст повідомлення'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Кому:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: NotificationTarget.values
                    .where((t) => t != NotificationTarget.personal)
                    .map((t) => ChoiceChip(
                          label: Text(t.displayName),
                          selected: _target == t,
                          onSelected: (_) => setState(() {
                            _target = t;
                            _selectedValues.clear();
                          }),
                        ))
                    .toList(),
              ),
              if (_target == NotificationTarget.ageGroup) ...[
                const SizedBox(height: 12),
                const Text(
                  'Оберіть роки народження:',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                if (_availableYears.isEmpty)
                  const Text(
                    'Немає спортсменів у системі',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  )
                else
                  ..._availableYears.map(
                    (y) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('$y р.н.',
                          style: const TextStyle(fontSize: 13)),
                      value: _selectedValues.contains(y.toString()),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedValues.add(y.toString());
                        } else {
                          _selectedValues.remove(y.toString());
                        }
                      }),
                    ),
                  ),
              ],
              if (_target == NotificationTarget.belt) ...[
                const SizedBox(height: 12),
                const Text(
                  'Оберіть рівні поясів:',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                ...BeltLevel.values.map(
                  (b) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(b.displayName,
                        style: const TextStyle(fontSize: 13)),
                    value: _selectedValues.contains(b.name),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedValues.add(b.name);
                      } else {
                        _selectedValues.remove(b.name);
                      }
                    }),
                  ),
                ),
              ],
              if (_target == NotificationTarget.top20age ||
                  _target == NotificationTarget.exceptTop20age) ...[
                const SizedBox(height: 12),
                if (_availableYears.isEmpty)
                  const Text(
                    'Немає спортсменів у системі',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: effectiveTop20Year,
                    decoration: const InputDecoration(
                        labelText: 'Рік народження'),
                    items: _availableYears
                        .map((y) => DropdownMenuItem(
                              value: y.toString(),
                              child: Text('$y'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _top20Year = v),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _loading ? null : () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: _loading ? null : _send,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Надіслати',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
