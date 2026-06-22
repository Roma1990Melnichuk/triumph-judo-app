import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'triumph_icon.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.tIcon,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final TIcon? tIcon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tIcon != null
                  ? TriumphIcon(tIcon!, size: 64)
                  : Icon(icon, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              if (action != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(onPressed: action, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
