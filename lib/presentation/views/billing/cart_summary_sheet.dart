import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'payment_modal.dart';
import 'pos_quick_quantity_dialog.dart';

class CartSummarySheet extends StatelessWidget {
  const CartSummarySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CartSummarySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // In landscape mode, screen height may be ~360-500dp, ensure at least 90% or minimum 320dp
    final sheetHeight = (screenHeight * 0.90).clamp(320.0, 750.0);

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
          child: const CartSummaryContent(isEmbedded: false),
        ),
      ),
    );
  }
}

class CartSummaryContent extends StatelessWidget {
  final bool isEmbedded;
  final VoidCallback? onClose;

  const CartSummaryContent({
    super.key,
    this.isEmbedded = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final items = billing.cartItems;
    final totals = billing.cartTotals;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isEmbedded ? const Border(left: BorderSide(color: AppColors.border)) : null,
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                if (!isEmbedded) ...[
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
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isEmbedded) ...[
                          const Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.accentNavy),
                          const SizedBox(width: 8),
                        ],
                        const Text(
                          'Current Order Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${billing.totalCartItemCount} items',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          billing.clearCart();
                          if (!isEmbedded && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                        label: const Text('Clear', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Your cart is empty.\nTap items to add them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final hasImage = item.product.imagePath != null &&
                          item.product.imagePath!.isNotEmpty;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dish thumbnail
                          if (hasImage) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 36,
                                height: 36,
                                color: AppColors.canvas,
                                child: Image.file(
                                  File(item.product.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],

                          // Item details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.format(item.unitPrice)} each',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Note: ${item.note}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryBlue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Quantity Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16, color: AppColors.accentNavy),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    billing.updateQuantity(item.product.id, item.quantity - 1);
                                  },
                                ),
                                InkWell(
                                  onTap: () {
                                    PosQuickQuantityDialog.show(
                                      context,
                                      product: item.product,
                                      currentQuantity: item.quantity,
                                      onQuantitySelected: (newQty) {
                                        billing.setCartItemQuantity(item.product, newQty);
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      '${item.quantity.toInt()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    billing.updateQuantity(item.product.id, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Total per item
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(item.netTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentNavy,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note, size: 18, color: AppColors.secondaryText),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _showItemOptions(context, item);
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Bill Calculation Summary Footer
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: const Border(top: BorderSide(color: AppColors.border)),
                borderRadius: !isEmbedded
                    ? const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusMedium))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryRow('Subtotal', CurrencyFormatter.format(totals.subtotal)),
                  if (totals.totalDiscount > 0)
                    _buildSummaryRow(
                      'Discount',
                      '- ${CurrencyFormatter.format(totals.totalDiscount)}',
                      textColor: AppColors.success,
                    ),
                  if (totals.taxAmount > 0)
                    _buildSummaryRow(
                      '${billing.taxSettings.taxName} (Tax)',
                      CurrencyFormatter.format(totals.taxAmount),
                    ),
                  if (totals.serviceCharge > 0)
                    _buildSummaryRow('Service Charge', CurrencyFormatter.format(totals.serviceCharge)),
                  if (totals.roundOff != 0)
                    _buildSummaryRow('Round Off', CurrencyFormatter.format(totals.roundOff)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totals.grandTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Hold Bill',
                          variant: ButtonVariant.outline,
                          icon: Icons.pause_circle_outline,
                          onPressed: () {
                            _showHoldBillPrompt(context, billing);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Proceed to Pay',
                          icon: Icons.payment,
                          onPressed: () {
                            if (!isEmbedded && Navigator.canPop(context)) {
                              Navigator.pop(context); // Close cart sheet
                            }
                            PaymentModal.show(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.accentNavy,
            ),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(BuildContext context, dynamic item) {
    final noteCtrl = TextEditingController(text: item.note);
    final discCtrl = TextEditingController(
      text: item.discountPercent > 0 ? item.discountPercent.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AlertDialog(
            title: Text('Edit ${item.product.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Kitchen / Item Note',
                    hintText: 'e.g. Less spicy, extra cheese',
                    controller: noteCtrl,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Item Discount (%)',
                    hintText: 'e.g. 10',
                    controller: discCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final billing = context.read<BillingProvider>();
                  billing.updateItemNote(item.product.id, noteCtrl.text);
                  final pct = double.tryParse(discCtrl.text) ?? 0.0;
                  billing.updateItemDiscount(item.product.id, percent: pct);
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHoldBillPrompt(BuildContext context, BillingProvider billing) {
    final tableCtrl = TextEditingController(text: billing.tableOrToken);

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AlertDialog(
            title: const Text('Hold Current Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter Table Number or Token reference to save this cart:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  CustomTextField(
                    hintText: 'e.g. Table 4, Token #12',
                    controller: tableCtrl,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx); // Close dialog
                  final res = await billing.holdCurrentBill(tableCtrl.text.trim());
                  if (context.mounted) {
                    if (res.isSuccess) {
                      if (!isEmbedded && Navigator.canPop(context)) {
                        Navigator.pop(context); // Close cart sheet
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bill saved to Held Orders!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.failure?.message ?? 'Failed to hold bill'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Hold Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
