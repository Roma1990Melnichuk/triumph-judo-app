import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../core/models/club_post_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/news_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NewsCommentsScreen
// ─────────────────────────────────────────────────────────────────────────────

class NewsCommentsScreen extends ConsumerStatefulWidget {
  const NewsCommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<NewsCommentsScreen> createState() =>
      _NewsCommentsScreenState();
}

class _NewsCommentsScreenState extends ConsumerState<NewsCommentsScreen> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserModelProvider).asData?.value;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (user == null || uid == null) return;

    setState(() => _sending = true);
    _commentCtrl.clear();

    await ref.read(clubPostNotifierProvider.notifier).addComment(
          postId: widget.postId,
          userId: uid,
          userName: user.name,
          text: text,
        );

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isCoach =
        ref.watch(currentUserModelProvider).asData?.value?.isCoach ?? false;
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: AppBackButton(onPressed: () => Navigator.maybePop(context)),
        title: const Text(
          'Коментарі',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Reactions bar ────────────────────────────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final post =
                  ref.watch(clubPostProvider(widget.postId)).asData?.value;
              if (post == null) return const SizedBox.shrink();

              final liked = post.userLiked(uid);
              final proud = post.userProud(uid);

              return Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Like reaction
                    GestureDetector(
                      onTap: () => ref
                          .read(clubPostNotifierProvider.notifier)
                          .toggleLike(widget.postId, uid, liked),
                      child: Row(
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: liked
                                ? AppColors.error
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              color: liked
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Proud reaction
                    GestureDetector(
                      onTap: () => ref
                          .read(clubPostNotifierProvider.notifier)
                          .toggleProud(widget.postId, uid, proud),
                      child: Row(
                        children: [
                          Icon(
                            proud
                                ? Icons.sports_martial_arts
                                : Icons.sports_martial_arts_outlined,
                            color: proud
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.proudCount}',
                            style: TextStyle(
                              color: proud
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Comments list ────────────────────────────────────────────────
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final commentsAsync =
                    ref.watch(postCommentsProvider(widget.postId));
                return commentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Помилка завантаження коментарів',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'Коментарів ще немає',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _CommentTile(
                          comment: comments[index],
                          isCoach: isCoach,
                          onDelete: () => _confirmDeleteComment(
                              context, ref, comments[index].id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // ── Comment input ────────────────────────────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final post =
                  ref.watch(clubPostProvider(widget.postId)).asData?.value;
              final commentsEnabled = post?.commentsEnabled ?? true;
              if (!commentsEnabled) return const SizedBox.shrink();

              final user =
                  ref.watch(currentUserModelProvider).asData?.value;
              final initials = _initials(user?.name ?? '');
              final bottomInset =
                  MediaQuery.of(context).viewInsets.bottom;

              return Container(
                color: AppColors.surface,
                padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomInset),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.avatarColor(user?.name ?? ''),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Написати коментар...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Send button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _commentCtrl,
                      builder: (context, value, _) {
                        final canSend =
                            value.text.trim().isNotEmpty && !_sending;
                        return IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: canSend
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          onPressed: canSend ? _sendComment : null,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteComment(
      BuildContext context, WidgetRef ref, String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text(
          'Видалити коментар?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Цю дію неможливо скасувати.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Скасувати',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Видалити',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(clubPostNotifierProvider.notifier)
          .deleteComment(widget.postId, commentId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CommentTile
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isCoach,
    required this.onDelete,
  });

  final ClubPostComment comment;
  final bool isCoach;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd.MM HH:mm').format(comment.createdAt);
    final initials = _initials(comment.userName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.avatarColor(comment.userId),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + date row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Coach delete button
          if (isCoach)
            IconButton(
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return '?';
}
