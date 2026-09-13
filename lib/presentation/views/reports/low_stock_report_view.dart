import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/custom_card.dart';
import '../inventory/stock_adjustment_dialog.dart';

class LowStockReportView extends StatelessWidget {
  final List<Product> lowStockProducts;

  const LowStockReportView({super.key, required this.lowStockProducts});

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
                'Low Stock Reorder Alerts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                ),
              ),
              AppBadge(
                text: '${lowStockProducts.length} Items',
                variant: lowStockProducts.isNotEmpty ? BadgeVariant.warning : BadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'All inventory levels are healthy!',
                      style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockProducts.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final product = lowStockProducts[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.categoryName} • Threshold: ${product.lowStockThreshold.toInt()} ${product.unit}',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.stockQuantity.toInt()} ${product.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: product.isOutOfStock ? AppColors.danger : AppColors.warning,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(product.sellingPrice),
                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primaryBlue, size: 20),
                      tooltip: 'Restock / Adjust',
                      onPressed: () {
                        StockAdjustmentDialog.show(context, product);
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
