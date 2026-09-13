import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'custom_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 48, color: AppColors.primaryBlueLight),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.accentNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                width: 180,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
