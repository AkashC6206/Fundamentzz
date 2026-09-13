import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/custom_card.dart';

class HeldBillsDialog extends StatelessWidget {
  const HeldBillsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HeldBillsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final heldBills = billing.heldBills;

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.85).clamp(320.0, 700.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: sheetHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
          ),
          child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.metallicSilver,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pause_circle_filled, color: AppColors.warning, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Held Orders (${heldBills.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Held Bills List
          Expanded(
            child: heldBills.isEmpty
                ? const AppEmptyState(
                    icon: Icons.pause_circle_outline,
                    title: 'No Held Bills',
                    message: 'Any cart saved during billing will appear here for easy resumption.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: heldBills.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = heldBills[index];
                      return CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bill.tableOrReference,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.format(bill.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${bill.items.length} items (${bill.items.map((i) => i.product.name).take(3).join(", ")}${bill.items.length > 3 ? "..." : ""})',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Held at: ${DateFormatter.formatDateTime(bill.heldAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    billing.discardHeldBill(bill.id);
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                  label: const Text('Discard', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    billing.resumeHeldBill(bill);
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Resume Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(110, 34),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  ),
);
}
}
