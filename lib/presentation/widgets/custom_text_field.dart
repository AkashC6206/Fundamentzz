import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentNavy,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.accentNavy,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? AppColors.canvas : AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
