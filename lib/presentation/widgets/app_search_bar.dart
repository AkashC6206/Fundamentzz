import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search items by name or SKU...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.accentNavy),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
