import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum BadgeVariant { success, warning, danger, primary, neutral }

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.success:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case BadgeVariant.warning:
        bg = AppColors.warning.withValues(alpha: 0.14);
        fg = const Color(0xFFD97706);
        break;
      case BadgeVariant.danger:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        break;
      case BadgeVariant.primary:
        bg = AppColors.primaryBlue.withValues(alpha: 0.12);
        fg = AppColors.primaryBlue;
        break;
      case BadgeVariant.neutral:
        bg = AppColors.canvas;
        fg = AppColors.secondaryText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
