import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/analytics_provider.dart';

class DateRangeFilterBar extends StatelessWidget {
  final AnalyticsDatePreset selectedPreset;
  final ValueChanged<AnalyticsDatePreset> onPresetSelected;
  final VoidCallback onCustomDateTap;

  const DateRangeFilterBar({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelected,
    required this.onCustomDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _buildChip(AnalyticsDatePreset.today, 'Today'),
          _buildChip(AnalyticsDatePreset.yesterday, 'Yesterday'),
          _buildChip(AnalyticsDatePreset.last7Days, 'Last 7 Days'),
          _buildChip(AnalyticsDatePreset.last30Days, 'Last 30 Days'),
          _buildChip(AnalyticsDatePreset.thisMonth, 'This Month'),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 14, color: AppColors.primaryBlue),
              label: const Text('Custom Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              backgroundColor: selectedPreset == AnalyticsDatePreset.custom ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.canvas,
              onPressed: onCustomDateTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(AnalyticsDatePreset preset, String label) {
    final isSelected = selectedPreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onPresetSelected(preset),
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.canvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.accentNavy,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }
}
