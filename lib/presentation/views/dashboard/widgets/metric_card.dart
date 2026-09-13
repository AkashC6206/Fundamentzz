import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../widgets/custom_card.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? trendText;
  final bool isPositiveTrend;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primaryBlue,
    this.onTap,
    this.trendText,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.accentNavy,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null || trendText != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (trendText != null) ...[
                  Icon(
                    isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositiveTrend ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trendText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositiveTrend ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
