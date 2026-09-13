import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/use_cases/get_analytics_usecase.dart';
import '../../../widgets/custom_card.dart';

class SalesTrendMiniChart extends StatelessWidget {
  final List<DailySalesPoint> trendData;
  final VoidCallback? onViewDetails;

  const SalesTrendMiniChart({
    super.key,
    required this.trendData,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = trendData.isNotEmpty && trendData.any((d) => d.salesAmount > 0);
    final maxAmount = trendData.isEmpty ? 100.0 : trendData.map((e) => e.salesAmount).reduce((a, b) => a > b ? a : b);
    final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.25;

    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '7-Day Sales Trend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Daily gross transaction volume',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Full Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: !hasData
                ? Center(
                    child: Text(
                      'No sales recorded in the past 7 days',
                      style: TextStyle(color: AppColors.secondaryText.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border.withValues(alpha: 0.6),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: maxY / 2,
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
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= trendData.length) return const SizedBox.shrink();
                              final point = trendData[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  DateFormat('E').format(point.date),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (trendData.length - 1).toDouble().clamp(0.0, 6.0),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.salesAmount);
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primaryBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3.5,
                                color: Colors.white,
                                strokeWidth: 2.2,
                                strokeColor: AppColors.primaryBlue,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBlue.withValues(alpha: 0.25),
                                AppColors.primaryBlue.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              if (index < 0 || index >= trendData.length) return null;
                              final point = trendData[index];
                              return LineTooltipItem(
                                '${DateFormat('dd MMM').format(point.date)}\n${CurrencyFormatter.format(point.salesAmount)}\n(${point.orderCount} bills)',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
