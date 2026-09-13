import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final BorderSide? borderSide;
  final double borderRadius;
  final Clip clipBehavior;
  final List<BoxShadow>? boxShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.p16),
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderSide,
    this.borderRadius = AppDimens.radiusMedium,
    this.clipBehavior = Clip.none,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(
          borderSide ?? const BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: clipBehavior,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
