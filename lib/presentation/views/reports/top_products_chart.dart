import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/use_cases/get_analytics_usecase.dart';
import '../../widgets/custom_card.dart';

class TopProductsChart extends StatelessWidget {
  final List<TopProductStat> topProducts;

  const TopProductsChart({super.key, required this.topProducts});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accentNavy,
            ),
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No item sales in this period', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.take(5).length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final product = topProducts[index];
                final rank = index + 1;
                return Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? const Color(0xFFF5A524)
                            : rank == 2
                                ? AppColors.metallicSilver
                                : rank == 3
                                    ? const Color(0xFFCD7F32)
                                    : AppColors.canvas,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: rank <= 3 ? Colors.white : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product.categoryName} • ${product.quantitySold.toInt()} sold',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(product.revenue),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
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
