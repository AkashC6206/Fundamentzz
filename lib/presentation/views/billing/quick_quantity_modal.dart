import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class QuickQuantityModal extends StatefulWidget {
  final Product product;
  final double currentQuantity;
  final String currentNote;

  const QuickQuantityModal({
    super.key,
    required this.product,
    this.currentQuantity = 1,
    this.currentNote = '',
  });

  static void show(
    BuildContext context, {
    required Product product,
    double currentQuantity = 1,
    String currentNote = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickQuantityModal(
        product: product,
        currentQuantity: currentQuantity > 0 ? currentQuantity : 1,
        currentNote: currentNote,
      ),
    );
  }

  @override
  State<QuickQuantityModal> createState() => _QuickQuantityModalState();
}

class _QuickQuantityModalState extends State<QuickQuantityModal> {
  late double _quantity;
  late TextEditingController _qtyCtrl;
  late TextEditingController _noteCtrl;

  final List<int> _presetQuantities = [1, 2, 3, 5, 10, 15, 20, 50];

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity;
    _qtyCtrl = TextEditingController(text: _quantity.toInt().toString());
    _noteCtrl = TextEditingController(text: widget.currentNote);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setQuantity(double q) {
    if (q < 0) q = 0;
    setState(() {
      _quantity = q;
      _qtyCtrl.text = q.toInt().toString();
    });
  }

  void _increment([double step = 1]) {
    _setQuantity(_quantity + step);
  }

  void _decrement([double step = 1]) {
    if (_quantity > 1) {
      _setQuantity(_quantity - step);
    } else {
      _setQuantity(0);
    }
  }

  void _applyToCart() {
    final qty = double.tryParse(_qtyCtrl.text) ?? _quantity;
    final billing = context.read<BillingProvider>();
    billing.addMultipleToCart(
      widget.product,
      qty,
      note: _noteCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.sellingPrice * _quantity;
    final hasImage = widget.product.imagePath != null &&
        widget.product.imagePath!.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: (MediaQuery.of(context).size.height * 0.90).clamp(360.0, 680.0),
        ),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: hasImage
                      ? Image.file(
                          File(widget.product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 24),
                        )
                      : const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.product.categoryName} • ${CurrencyFormatter.format(widget.product.sellingPrice)} per ${widget.product.unit}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),

          const SizedBox(height: 16),

          // Main Quantity Stepper with Direct Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Quantity:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                ),
                Row(
                  children: [
                    // Decrement Button
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppColors.danger, size: 32),
                      onPressed: () => _decrement(1),
                    ),
                    // Quantity Input Field
                    Container(
                      width: 60,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primaryBlue),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            setState(() => _quantity = parsed);
                          }
                        },
                      ),
                    ),
                    // Increment Button
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 32),
                      onPressed: () => _increment(1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quick Preset Pills (+1, +2, +3, +5, +10, +20)
          const Text(
            'Quick Quantity Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetQuantities.map((preset) {
              final isSelected = _quantity.toInt() == preset;
              return InkWell(
                onTap: () => _setQuantity(preset.toDouble()),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBlue : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.border),
                  ),
                  child: Text(
                    '+$preset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.accentNavy,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Cooking Note / Special Instructions
          CustomTextField(
            label: 'Kitchen / Cooking Note (Optional)',
            hintText: 'e.g. Extra spicy, no onion, separate dressing',
            controller: _noteCtrl,
          ),

          const SizedBox(height: 18),

          // Summary & Apply Button
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Total:', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  Text(
                    CurrencyFormatter.format(totalPrice),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: _quantity == 0 ? 'REMOVE FROM CART' : 'ADD ${_quantity.toInt()} TO CART',
                  icon: _quantity == 0 ? Icons.delete_outline : Icons.shopping_bag,
                  variant: _quantity == 0 ? ButtonVariant.danger : ButtonVariant.primary,
                  onPressed: _applyToCart,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
);
}
}
