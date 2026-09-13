import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/use_cases/get_analytics_usecase.dart';
import '../../widgets/custom_card.dart';

class PaymentModeDonutChart extends StatelessWidget {
  final List<PaymentModeStat> paymentModes;

  const PaymentModeDonutChart({super.key, required this.paymentModes});

  static Color _getPaymentColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppColors.success;
      case PaymentMode.upi:
        return AppColors.primaryBlue;
      case PaymentMode.card:
        return AppColors.primaryBlueDark;
      case PaymentMode.credit:
        return AppColors.warning;
      case PaymentMode.split:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeModes = paymentModes.where((m) => m.totalAmount > 0).toList();

    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Mode Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accentNavy,
            ),
          ),
          const SizedBox(height: 16),
          if (activeModes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No payment data available for this range', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: activeModes.map((stat) {
                    final color = _getPaymentColor(stat.mode);
                    return PieChartSectionData(
                      color: color,
                      value: stat.totalAmount,
                      title: '${stat.percentage.toStringAsFixed(0)}%',
                      radius: 36,
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
              itemCount: activeModes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final stat = activeModes[index];
                final color = _getPaymentColor(stat.mode);
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
                        '${stat.name} (${stat.transactionCount} bills)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentNavy),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(stat.totalAmount)} (${stat.percentage}%)',
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
