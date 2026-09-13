import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/sale.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/custom_card.dart';

class RecentSalesTicker extends StatelessWidget {
  final List<Sale> recentSales;
  final ValueChanged<Sale> onSaleTap;
  final VoidCallback onViewAll;

  const RecentSalesTicker({
    super.key,
    required this.recentSales,
    required this.onSaleTap,
    required this.onViewAll,
  });

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
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No transactions recorded today',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.take(5).length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final sale = recentSales[index];
                return InkWell(
                  onTap: () => onSaleTap(sale),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                        ),
                        child: const Icon(Icons.receipt_long, size: 18, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${sale.invoiceNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentNavy,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AppBadge(
                                  text: sale.paymentMode.name.toUpperCase(),
                                  variant: sale.paymentMode == PaymentMode.credit ? BadgeVariant.warning : BadgeVariant.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sale.customerName ?? "Walk-in Guest"} • ${sale.totalItemCount} items • ${DateFormatter.formatTime(sale.createdAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(sale.totalAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentNavy,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
