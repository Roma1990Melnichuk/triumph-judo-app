import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/child_model.dart';
import '../../../core/models/membership_model.dart';
import '../../../features/individual_training/providers/individual_training_provider.dart';
import '../../../features/schedule/providers/group_provider.dart';
import '../../../shared/widgets/belt_badge.dart';
import '../../../shared/widgets/default_avatar.dart';
import '../../../shared/widgets/triumph_icon.dart';

class ChildCard extends ConsumerWidget {
  const ChildCard({
    super.key,
    required this.child,
    required this.rank,
    required this.onTap,
    this.isOwn = false,
    this.membershipStatus,
    this.sameYearRank,
    this.sameYearTotal,
    this.sameWeightRank,
    this.sameWeightTotal,
    this.membershipEndDate,
    this.showAttendance = false,
  });

  final ChildModel child;
  final int rank;
  final VoidCallback onTap;
  final bool isOwn;
  final MembershipStatus? membershipStatus;
  final int? sameYearRank;
  final int? sameYearTotal;
  final int? sameWeightRank;
  final int? sameWeightTotal;
  final DateTime? membershipEndDate;
  final bool showAttendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStats = showAttendance
        ? ref.watch(childAttendanceStatsProvider(child.id)).value
        : null;
    final indivCount = showAttendance
        ? ref.watch(childConfirmedTrainingCountProvider(child.id))
        : 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Rank ─────────────────────────────────────────────────────
              SizedBox(
                width: 36,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // ── Avatar ───────────────────────────────────────────────────
              child.photoUrl != null
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          CachedNetworkImageProvider(child.photoUrl!),
                    )
                  : DefaultAvatarCircle(
                      gender: child.gender,
                      radius: 24,
                      seed: child.id,
                    ),
              const SizedBox(width: 12),

              // ── Info ─────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Row(children: [
                      Expanded(
                        child: Text(
                          child.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500, // Inter Medium
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwn)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ваша дитина',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),

                    // Belt + year + weight
                    Row(children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: BeltBadge(
                              belt: child.currentBelt,
                              size: BeltBadgeSize.small),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${child.birthYear} р.н.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (child.weightCategory.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          displayWeight(child.weightCategory),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ]),

                    // Belt-ready badge
                    if (child.beltReady) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 10, color: AppColors.success),
                            SizedBox(width: 3),
                            Text(
                              'Готовий до здачі',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Attendance % and individual training count
                    if (showAttendance && attendanceStats != null &&
                        attendanceStats.total > 0) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(AppColors.info, BlendMode.srcIn),
                          child: TriumphIcon(TIcon.calendar, size: 11),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Відвід.: ${attendanceStats.pct.round()}%',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600),
                        ),
                        if (indivCount > 0) ...[
                          const SizedBox(width: 8),
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                            child: TriumphIcon(TIcon.athlete, size: 11),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Інд.: $indivCount',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),

              // ── Points + membership dot ──────────────────────────────────
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${child.totalPoints}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent, // gold
                    ),
                  ),
                  const Text(
                    'балів',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (membershipStatus != null) ...[
                    const SizedBox(height: 4),
                    _MembershipDot(
                      status: membershipStatus!,
                      endDate: membershipEndDate,
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.surface3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipDot extends StatelessWidget {
  const _MembershipDot({required this.status, this.endDate});

  final MembershipStatus status;
  final DateTime? endDate;

  Color get _color {
    switch (status) {
      case MembershipStatus.active:
        return const Color(0xFF27AE60);
      case MembershipStatus.expiringSoon:
        return AppColors.orange;
      case MembershipStatus.expired:
        return AppColors.primary;
    }
  }

  String get _label {
    switch (status) {
      case MembershipStatus.active:
        return 'Активний';
      case MembershipStatus.expiringSoon:
        return 'Закінч.';
      case MembershipStatus.expired:
        return 'Простр.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = endDate != null
        ? DateFormat('dd.MM.yy').format(endDate!)
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          dateStr != null ? '$_label до $dateStr' : _label,
          style: TextStyle(
            fontSize: 9,
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
