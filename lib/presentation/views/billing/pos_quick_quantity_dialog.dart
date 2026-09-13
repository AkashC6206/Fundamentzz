import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';

/// Fast, compact POS Quantity Dialog using the device's native numeric keyboard and quick presets.
class PosQuickQuantityDialog extends StatefulWidget {
  final Product product;
  final double currentQuantity;
  final ValueChanged<double> onQuantitySelected;

  const PosQuickQuantityDialog({
    super.key,
    required this.product,
    required this.currentQuantity,
    required this.onQuantitySelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required double currentQuantity,
    required ValueChanged<double> onQuantitySelected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PosQuickQuantityDialog(
        product: product,
        currentQuantity: currentQuantity,
        onQuantitySelected: onQuantitySelected,
      ),
    );
  }

  @override
  State<PosQuickQuantityDialog> createState() => _PosQuickQuantityDialogState();
}

class _PosQuickQuantityDialogState extends State<PosQuickQuantityDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  final List<int> _quickPresets = [2, 5, 10, 15, 20, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    final initial = widget.currentQuantity > 0 ? widget.currentQuantity : 1.0;
    final initialStr = initial % 1 == 0 ? initial.toInt().toString() : initial.toString();
    _controller = TextEditingController(text: initialStr);
    _focusNode = FocusNode();

    // Select all text on open so typing replaces current quantity immediately
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _currentQuantityValue {
    return double.tryParse(_controller.text) ?? 0.0;
  }

  void _onPresetPressed(int preset) {
    HapticFeedback.mediumImpact();
    _controller.text = preset.toString();
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _onStep(double delta) {
    HapticFeedback.lightImpact();
    final current = _currentQuantityValue;
    final next = (current + delta).clamp(0.0, 9999.0);
    final formatted = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    _controller.text = formatted;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _onConfirm() {
    HapticFeedback.mediumImpact();
    final val = _currentQuantityValue;
    widget.onQuantitySelected(val <= 0 ? 0.0 : val);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final qty = _currentQuantityValue;
    final total = widget.product.sellingPrice * qty;
    final hasImage = widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLarge)),
      elevation: 16,
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColors.canvas,
                      child: hasImage
                          ? Image.file(
                              File(widget.product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 22),
                            )
                          : const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.format(widget.product.sellingPrice)} each',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Digital Readout Screen with Numeric Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppColors.danger, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _onStep(-1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ORDER QTY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                              letterSpacing: 0.8,
                            ),
                          ),
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentNavy,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: '0',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ITEM TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _onStep(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Quick Bulk Preset Chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _quickPresets.map((preset) {
                    final isCurrent = qty == preset.toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _onPresetPressed(preset),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primaryBlue : AppColors.canvas,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent ? AppColors.primaryBlue : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$preset',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? Colors.white : AppColors.accentNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (widget.currentQuantity > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onQuantitySelected(0);
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                          ),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  if (widget.currentQuantity > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                        ),
                      ),
                      child: Text(
                        qty <= 0
                            ? 'Remove from Order'
                            : 'Set Quantity',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
