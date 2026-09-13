import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/use_cases/get_analytics_usecase.dart';
import '../../widgets/custom_card.dart';

class CategorySalesChart extends StatelessWidget {
  final List<CategorySalesStat> categorySales;

  const CategorySalesChart({super.key, required this.categorySales});

  static const List<Color> _chartColors = [
    AppColors.primaryBlue,
    AppColors.primaryBlueDark,
    AppColors.primaryBlueLight,
    AppColors.info,
    AppColors.warning,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final hasData = categorySales.isNotEmpty && categorySales.any((c) => c.revenue > 0);

    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category-wise Sales',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accentNavy,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No category sales recorded', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: categorySales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final color = _chartColors[index % _chartColors.length];
                    return PieChartSectionData(
                      color: color,
                      value: stat.revenue,
                      title: '${stat.percentage.toStringAsFixed(0)}%',
                      radius: 42,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categorySales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final stat = categorySales[index];
                final color = _chartColors[index % _chartColors.length];
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stat.categoryName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentNavy),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(stat.revenue)} (${stat.percentage}%)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
