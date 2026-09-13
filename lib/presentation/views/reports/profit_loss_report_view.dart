import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/use_cases/get_analytics_usecase.dart';
import '../../widgets/custom_card.dart';

class ProfitLossReportView extends StatelessWidget {
  final AnalyticsReportData data;

  const ProfitLossReportView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profit & Loss Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (data.netProfit >= 0 ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.profitMargin >= 0 ? "+" : ""}${data.profitMargin}% Margin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: data.netProfit >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detailed Table
          _buildRow('Total Sales Revenue (Gross)', CurrencyFormatter.format(data.totalRevenue), isBold: true),
          _buildRow('(-) Cost of Goods Sold (COGS)', '- ${CurrencyFormatter.format(data.totalCostOfGoods)}', textColor: AppColors.secondaryText),
          _buildRow('(=) Gross Margin', CurrencyFormatter.format(data.grossProfit), isBold: true, textColor: AppColors.primaryBlue),
          const Divider(height: 12),
          _buildRow('(-) Total Operating Expenses', '- ${CurrencyFormatter.format(data.totalExpenses)}', textColor: AppColors.danger),
          _buildRow('(-) Tax Paid / Collected', CurrencyFormatter.format(data.totalTax), textColor: AppColors.secondaryText),
          _buildRow('Discounts Granted', CurrencyFormatter.format(data.totalDiscount), textColor: AppColors.secondaryText),
          const Divider(height: 16, thickness: 1.2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET ESTIMATED PROFIT',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
              ),
              Text(
                CurrencyFormatter.format(data.netProfit),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: data.netProfit >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isBold ? AppColors.accentNavy : AppColors.secondaryText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor ?? AppColors.accentNavy,
            ),
          ),
        ],
      ),
    );
  }
}
