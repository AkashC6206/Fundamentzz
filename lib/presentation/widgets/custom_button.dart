import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

enum ButtonVariant { primary, secondary, danger, outline, ghost }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.height = AppDimens.buttonHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primaryBlue;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.primaryBlueDark;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primaryBlue;
        border = const BorderSide(color: AppColors.border, width: 1.2);
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.accentNavy;
        border = BorderSide.none;
        break;
    }

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      height: height,
      width: width ?? (variant == ButtonVariant.ghost ? null : double.infinity),
      child: Material(
        color: onPressed == null ? AppColors.metallicSilver.withValues(alpha: 0.3) : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          side: border,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
