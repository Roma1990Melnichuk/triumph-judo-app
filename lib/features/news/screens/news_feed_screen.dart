import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/club_post_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/news_provider.dart';

// ── Type badge metadata ───────────────────────────────────────────────────────

Color _typeColor(ClubPostType type) => switch (type) {
      ClubPostType.photoReport  => const Color(0xFFD50000),
      ClubPostType.competition  => const Color(0xFF1565C0),
      ClubPostType.achievement  => const Color(0xFF2E7D32),
      ClubPostType.honorBoard   => const Color(0xFFFFD21A),
      ClubPostType.announcement => const Color(0xFFFF8A00),
      ClubPostType.clubNews     => const Color(0xFF7B1FA2),
    };

String _typeEmoji(ClubPostType type) => switch (type) {
      ClubPostType.photoReport  => '📷',
      ClubPostType.competition  => '🏆',
      ClubPostType.achievement  => '🥇',
      ClubPostType.honorBoard   => '⭐',
      ClubPostType.announcement => '📢',
      ClubPostType.clubNews     => '📰',
    };

bool _typeHasDarkText(ClubPostType type) => type == ClubPostType.honorBoard;

// ── Screen ────────────────────────────────────────────────────────────────────

class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.asData?.value;
    final filter = ref.watch(newsFeedFilterProvider);
    final isCoach = user?.isCoach ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isCoach
          ? FloatingActionButton(
              onPressed: () => context.push('/news/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            title: const Text(
              'Стрічка новин',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textPrimary,
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          _FilterChipsHeader(user: user),

          // ── Feed content ─────────────────────────────────────────────────
          _FeedContent(filter: filter, user: user),
        ],
      ),
    );
  }
}

// ── Filter chips persistent header ───────────────────────────────────────────

class _FilterChipsHeader extends ConsumerWidget {
  const _FilterChipsHeader({required this.user});

  final dynamic user; // UserModel?

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(newsFeedFilterProvider);

    final filters = NewsFeedFilter.values.where((f) {
      // Only show myChild chip if user is a parent with at least one child
      if (f == NewsFeedFilter.myChild) {
        return user != null && (user.isParent as bool) && (user.childIds as List).isNotEmpty;
      }
      return true;
    }).toList();

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverChipHeaderDelegate(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: filters.map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f.label,
                    isSelected: isSelected,
                    onTap: () {
                      if (f == NewsFeedFilter.honorBoard) {
                        context.push('/news/honor-board');
                      } else {
                        ref.read(newsFeedFilterProvider.notifier).state = f;
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverChipHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SliverChipHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SliverChipHeaderDelegate oldDelegate) => true;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSoft,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Feed content ──────────────────────────────────────────────────────────────

class _FeedContent extends ConsumerWidget {
  const _FeedContent({required this.filter, required this.user});

  final NewsFeedFilter filter;
  final dynamic user; // UserModel?

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filter == NewsFeedFilter.myChild &&
        user != null &&
        (user.isParent as bool) &&
        (user.childIds as List).isNotEmpty) {
      final childId = (user.childIds as List<String>).first;
      final postsAsync = ref.watch(postsByChildProvider(childId));

      return postsAsync.when(
        loading: () => const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, __) => const SliverFillRemaining(
          child: Center(
            child: Text(
              'Помилка завантаження',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const _EmptyState();
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Фото з моєю дитиною',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }
                final post = posts[i - 1];
                return _PostCard(post: post);
              },
              childCount: posts.length + 1,
            ),
          );
        },
      );
    }

    // All other filters — use clubPostsProvider with client-side filtering
    final postsAsync = ref.watch(clubPostsProvider);

    return postsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SliverFillRemaining(
        child: Center(
          child: Text(
            'Помилка завантаження',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (allPosts) {
        final posts = _applyFilter(allPosts, filter);
        if (posts.isEmpty) {
          return const _EmptyState();
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _PostCard(post: posts[i]),
            childCount: posts.length,
          ),
        );
      },
    );
  }

  List<ClubPost> _applyFilter(List<ClubPost> posts, NewsFeedFilter filter) {
    return switch (filter) {
      NewsFeedFilter.all         => posts,
      NewsFeedFilter.photoReport => posts.where((p) => p.type == ClubPostType.photoReport).toList(),
      NewsFeedFilter.competition => posts.where((p) => p.type == ClubPostType.competition).toList(),
      NewsFeedFilter.achievement => posts.where((p) => p.type == ClubPostType.achievement).toList(),
      NewsFeedFilter.honorBoard  => posts.where((p) => p.type == ClubPostType.honorBoard).toList(),
      NewsFeedFilter.myChild     => posts,
    };
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Публікацій ще немає',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    final dateStr = post.publishedAt != null
        ? DateFormat('d MMM yyyy', 'uk').format(post.publishedAt!)
        : '';
    final badgeColor = _typeColor(post.type);
    final badgeTextColor =
        _typeHasDarkText(post.type) ? const Color(0xFF0A0000) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => context.push('/news/${post.id}'),
          child: Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderSoft, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cover image / placeholder ─────────────────────────────
                _CoverSection(post: post, badgeColor: badgeColor, badgeTextColor: badgeTextColor),

                // ── Text content ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      if (post.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          post.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Date row
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          _SmallTypeBadge(
                            label: post.type.label,
                            color: badgeColor,
                            textColor: badgeTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Divider ───────────────────────────────────────────────
                const Divider(
                  color: AppColors.borderSoft,
                  thickness: 0.5,
                  height: 0.5,
                ),

                // ── Stats row ─────────────────────────────────────────────
                _StatsRow(post: post),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cover section (image or placeholder) ─────────────────────────────────────

class _CoverSection extends StatelessWidget {
  const _CoverSection({
    required this.post,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final ClubPost post;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: post.coverImageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.surface2,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surface2,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
            ),
            // Bottom gradient overlay
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            // Pinned icon — top left
            if (post.isPinned)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.push_pin,
                    color: AppColors.accent,
                    size: 16,
                  ),
                ),
              ),
            // Type badge — top right
            Positioned(
              top: 10,
              right: 10,
              child: _TypeBadge(
                label: post.type.label,
                color: badgeColor,
                textColor: badgeTextColor,
              ),
            ),
          ],
        ),
      );
    }

    // No cover: gradient placeholder with emoji + label
    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  badgeColor.withValues(alpha: 0.35),
                  badgeColor.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _typeEmoji(post.type),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 6),
                Text(
                  post.type.label,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Pinned icon
          if (post.isPinned)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.push_pin,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
            ),
          // Type badge
          Positioned(
            top: 10,
            right: 10,
            child: _TypeBadge(
              label: post.type.label,
              color: badgeColor,
              textColor: badgeTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type badge (top of card) ──────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Small type badge (in-card row) ───────────────────────────────────────────

class _SmallTypeBadge extends StatelessWidget {
  const _SmallTypeBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.post});

  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (post.photosCount > 0) ...[
            Text(
              '📷 ${post.photosCount} фото',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '❤️ ${post.likesCount}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '💬 ${post.commentsCount}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/news/${post.id}'),
            child: const Text(
              'Переглянути →',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
