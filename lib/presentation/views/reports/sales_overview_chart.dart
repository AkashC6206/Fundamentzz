import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/use_cases/get_analytics_usecase.dart';
import '../../widgets/custom_card.dart';

class SalesOverviewChart extends StatelessWidget {
  final List<DailySalesPoint> salesTrend;

  const SalesOverviewChart({super.key, required this.salesTrend});

  @override
  Widget build(BuildContext context) {
    final hasData = salesTrend.isNotEmpty && salesTrend.any((d) => d.salesAmount > 0);
    final maxAmount = salesTrend.isEmpty ? 100.0 : salesTrend.map((e) => e.salesAmount).reduce((a, b) => a > b ? a : b);
    final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.25;

    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales & Revenue Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Daily Gross Revenue',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: !hasData
                ? const Center(
                    child: Text(
                      'No sales transactions in the selected period',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = salesTrend[group.x.toInt()];
                            return BarTooltipItem(
                              '${DateFormat('dd MMM').format(point.date)}\n${CurrencyFormatter.format(rod.toY)}\n(${point.orderCount} bills)',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: maxY / 3,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value >= maxY * 0.95) return const SizedBox.shrink();
                              return Text(
                                CurrencyFormatter.formatCompact(value, symbol: '₹'),
                                style: const TextStyle(fontSize: 9, color: AppColors.secondaryText),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= salesTrend.length) return const SizedBox.shrink();
                              final point = salesTrend[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  DateFormat(salesTrend.length > 10 ? 'd' : 'E').format(point.date),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.7),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: salesTrend.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.salesAmount,
                              color: AppColors.primaryBlue,
                              width: salesTrend.length > 14 ? 8 : 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              gradient: LinearGradient(
                                colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
