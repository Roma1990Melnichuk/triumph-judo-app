import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/club_post_model.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/news/providers/news_provider.dart';
import 'package:judo_app/shared/widgets/app_back_button.dart';

// ── Type palette ──────────────────────────────────────────────────────────────

Color _typeColor(ClubPostType type) => switch (type) {
      ClubPostType.photoReport  => const Color(0xFF7B1FA2),
      ClubPostType.competition  => AppColors.primary,
      ClubPostType.achievement  => AppColors.accent,
      ClubPostType.honorBoard   => const Color(0xFF1565C0),
      ClubPostType.announcement => AppColors.orange,
      ClubPostType.clubNews     => AppColors.success,
    };

// ── Main screen ───────────────────────────────────────────────────────────────

class NewsPostScreen extends ConsumerWidget {
  const NewsPostScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(clubPostProvider(postId));
    final userAsync = ref.watch(currentUserModelProvider);
    final authAsync = ref.watch(authStateProvider);

    final user    = userAsync.asData?.value;
    final fireUser = authAsync.asData?.value;
    final uid     = fireUser?.uid ?? '';

    return postAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: const AppBackButton(),
        ),
        body: const Center(
          child: Text(
            'Помилка завантаження',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (post) {
        if (post == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leading: const AppBackButton(),
            ),
            body: const Center(
              child: Text(
                'Пост не знайдено',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final isCoach       = user?.isCoach ?? false;
        final liked         = uid.isNotEmpty && post.userLiked(uid);
        final proud         = uid.isNotEmpty && post.userProud(uid);
        final isPhotoOrComp = post.type == ClubPostType.photoReport ||
            post.type == ClubPostType.competition;

        final hasCompInfo = post.competitionName != null ||
            post.competitionCity != null ||
            post.competitionVenue != null ||
            post.competitionDate != null ||
            post.mentions.isNotEmpty;

        final hasMedals = post.goldMedals != null ||
            post.silverMedals != null ||
            post.bronzeMedals != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: _ReactionsBar(
            post: post,
            uid: uid,
            liked: liked,
            proud: proud,
            onLike: () => ref
                .read(clubPostNotifierProvider.notifier)
                .toggleLike(postId, uid, liked),
            onProud: () => ref
                .read(clubPostNotifierProvider.notifier)
                .toggleProud(postId, uid, proud),
            onComments: post.commentsEnabled
                ? () => context.push('/news/$postId/comments')
                : null,
          ),
          body: CustomScrollView(
            slivers: [
              // ── SliverAppBar ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.background,
                leading: AppBackButton(onPressed: () => context.pop()),
                actions: [
                  if (isCoach)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textPrimary),
                      onPressed: () =>
                          context.push('/news/${post.id}/edit'),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image / gradient fallback
                      if (post.coverImageUrl != null &&
                          post.coverImageUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: post.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _coverFallback(post.type),
                          errorWidget: (_, __, ___) =>
                              _coverFallback(post.type),
                        )
                      else
                        _coverFallback(post.type),

                      // Bottom gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Type badge — bottom-left
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: _TypeBadge(type: post.type),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Author + date row
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(post.publishedAt ?? post.createdAt),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Coach comment block for photoReport (shown before general content)
                      if (post.type == ClubPostType.photoReport &&
                          post.content.isNotEmpty)
                        _CoachCommentSection(content: post.content),

                      // General content (non-photoReport)
                      if (post.type != ClubPostType.photoReport &&
                          post.content.isNotEmpty) ...[
                        Text(
                          post.content,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Photo/competition extra sections ──────────────────────────
              if (isPhotoOrComp) ...[
                // "Про змагання"
                if (hasCompInfo)
                  SliverToBoxAdapter(
                    child: _CompetitionInfoSection(post: post),
                  ),

                // "Медалі клубу"
                if (hasMedals)
                  SliverToBoxAdapter(
                    child: _MedalsSection(post: post),
                  ),

                // "Фотоальбом"
                if (post.images.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PhotoAlbumSection(post: post),
                  ),

                // "Спортсмени на фото"
                if (post.mentions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _AthleteChipsSection(post: post),
                  ),

                // "Наші чемпіони" — photoReport only
                if (post.type == ClubPostType.photoReport &&
                    post.mentions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _ChampionsSection(post: post),
                  ),
              ],

              // ── Comments button ───────────────────────────────────────────
              if (post.commentsEnabled)
                SliverToBoxAdapter(
                  child: _CommentsRowButton(
                    post: post,
                    onTap: () => context.push('/news/$postId/comments'),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static Widget _coverFallback(ClubPostType type) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _typeColor(type).withValues(alpha: 0.6),
            AppColors.background,
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      DateFormat('d MMM yyyy', 'uk').format(date);
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ClubPostType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _typeColor(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Coach comment section ─────────────────────────────────────────────────────

class _CoachCommentSection extends StatelessWidget {
  const _CoachCommentSection({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment_outlined, size: 16, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'Коментар тренера',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Competition info section ───────────────────────────────────────────────────

class _CompetitionInfoSection extends StatelessWidget {
  const _CompetitionInfoSection({required this.post});
  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Про змагання',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (post.competitionName != null)
            _InfoRow(
              icon: Icons.emoji_events_outlined,
              text: post.competitionName!,
            ),
          if (post.competitionCity != null || post.competitionVenue != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: [post.competitionVenue, post.competitionCity]
                  .whereType<String>()
                  .join(', '),
            ),
          if (post.competitionDate != null)
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              text: DateFormat('d MMMM yyyy', 'uk').format(post.competitionDate!),
            ),
          if (post.mentions.isNotEmpty)
            _InfoRow(
              icon: Icons.group_outlined,
              text: 'Учасників: ${post.mentions.length}',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medals section ────────────────────────────────────────────────────────────

class _MedalsSection extends StatelessWidget {
  const _MedalsSection({required this.post});
  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          const Text(
            'Медалі клубу',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MedalColumn(
                asset: 'assets/images/medal_gold.png',
                count: post.goldMedals ?? 0,
                color: AppColors.goldMedal,
              ),
              _MedalColumn(
                asset: 'assets/images/medal_silver.png',
                count: post.silverMedals ?? 0,
                color: AppColors.silverMedal,
              ),
              _MedalColumn(
                asset: 'assets/images/medal_bronze.png',
                count: post.bronzeMedals ?? 0,
                color: AppColors.bronzeMedal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedalColumn extends StatelessWidget {
  const _MedalColumn({
    required this.asset,
    required this.count,
    required this.color,
  });
  final String asset;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(child: Image.asset(asset, width: 64, height: 64)),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ── Photo album section ───────────────────────────────────────────────────────

class _PhotoAlbumSection extends StatelessWidget {
  const _PhotoAlbumSection({required this.post});
  final ClubPost post;

  void _openGallery(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _GalleryDialog(
        images: post.images,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Фотоальбом',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${post.images.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post.images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final img = post.images[index];
              final url = img.thumbnailUrl ?? img.imageUrl;
              return GestureDetector(
                onTap: () => _openGallery(context, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: AppColors.surface2),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface2,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
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

// ── Gallery full-screen dialog ─────────────────────────────────────────────────

class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({required this.images, required this.initialIndex});
  final List<ClubPostImage> images;
  final int initialIndex;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.95),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final img = widget.images[i];
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: img.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          // Caption
          if (widget.images[_currentIndex].caption != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 16,
              right: 16,
              child: Text(
                widget.images[_currentIndex].caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          // Page indicator
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Athlete chips section ──────────────────────────────────────────────────────

class _AthleteChipsSection extends StatelessWidget {
  const _AthleteChipsSection({required this.post});
  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Спортсмени на фото',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${post.mentions.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: post.mentions.map((m) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Text(
                  m.athleteName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Champions section ─────────────────────────────────────────────────────────

class _ChampionsSection extends StatelessWidget {
  const _ChampionsSection({required this.post});
  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    final shown = post.mentions.take(5).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Наші чемпіони',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final mention = shown[i];
                final avatarColor = AppColors.avatarColor(mention.athleteId);
                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColor,
                        child: Text(
                          mention.athleteName.isNotEmpty
                              ? mention.athleteName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mention.athleteName} 🏆',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comments row button ───────────────────────────────────────────────────────

class _CommentsRowButton extends StatelessWidget {
  const _CommentsRowButton({required this.post, required this.onTap});
  final ClubPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              'Коментарі (${post.commentsCount})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Reactions bottom bar ───────────────────────────────────────────────────────

class _ReactionsBar extends StatelessWidget {
  const _ReactionsBar({
    required this.post,
    required this.uid,
    required this.liked,
    required this.proud,
    required this.onLike,
    required this.onProud,
    this.onComments,
  });

  final ClubPost post;
  final String uid;
  final bool liked;
  final bool proud;
  final VoidCallback onLike;
  final VoidCallback onProud;
  final VoidCallback? onComments;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
      child: Row(
        children: [
          // Like button
          _ReactionButton(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            iconColor: liked ? AppColors.primary : AppColors.textSecondary,
            label: '${post.likesCount}',
            onTap: uid.isNotEmpty ? onLike : null,
          ),
          const SizedBox(width: 16),
          // Proud button
          _ProudButton(
            proud: proud,
            count: post.proudCount,
            onTap: uid.isNotEmpty ? onProud : null,
          ),
          const Spacer(),
          // Comments shortcut
          if (onComments != null)
            _ReactionButton(
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.textSecondary,
              label: '${post.commentsCount}',
              onTap: onComments,
            ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProudButton extends StatelessWidget {
  const _ProudButton({
    required this.proud,
    required this.count,
    this.onTap,
  });
  final bool proud;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            '💪',
            style: TextStyle(
              fontSize: 20,
              color: proud ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Пишаємося  $count',
            style: TextStyle(
              color: proud ? AppColors.accent : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: proud ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
