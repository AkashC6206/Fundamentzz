import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_adjustment.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockAdjustmentDialog(product: product),
    );
  }

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  StockAdjustmentType _selectedType = StockAdjustmentType.stockIn;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController(text: 'Purchase / Restock');
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  final List<String> _presetReasons = [
    'Purchase / Restock',
    'Inventory Damage',
    'Physical Audit Count Discrepancy',
    'Kitchen Spoilage / Wastage',
    'Complimentary / Tasting',
    'Return from Customer',
  ];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);

    double newStock = widget.product.stockQuantity;
    double change = qty;

    if (_selectedType == StockAdjustmentType.stockIn) {
      newStock += qty;
      change = qty;
    } else if (_selectedType == StockAdjustmentType.stockOut) {
      newStock -= qty;
      change = -qty;
    } else if (_selectedType == StockAdjustmentType.setExact) {
      change = qty - widget.product.stockQuantity;
      newStock = qty;
    }

    final adj = StockAdjustment(
      id: const Uuid().v4(),
      productId: widget.product.id,
      productName: widget.product.name,
      type: _selectedType,
      quantityChange: change,
      newStockQuantity: newStock,
      reason: _reasonCtrl.text.trim(),
      timestamp: DateTime.now(),
      notes: _notesCtrl.text.trim(),
    );

    final res = await context.read<InventoryProvider>().adjustStock(adj);

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated for "${widget.product.name}"!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failure?.message ?? 'Failed to adjust stock'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adjust Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                  Text(widget.product.name, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),

          // Current Stock Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Stock on Record:', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                Text(
                  '${widget.product.stockQuantity.toInt()} ${widget.product.unit}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Type Segmented Control
          Row(
            children: [
              _buildTypeChip(StockAdjustmentType.stockIn, 'Stock IN (+)', Icons.add_circle_outline, AppColors.success),
              const SizedBox(width: 8),
              _buildTypeChip(StockAdjustmentType.stockOut, 'Stock OUT (-)', Icons.remove_circle_outline, AppColors.danger),
              const SizedBox(width: 8),
              _buildTypeChip(StockAdjustmentType.setExact, 'Set Exact', Icons.tune, AppColors.primaryBlue),
            ],
          ),

          const SizedBox(height: 14),

          CustomTextField(
            label: _selectedType == StockAdjustmentType.setExact ? 'New Exact Quantity *' : 'Adjustment Quantity *',
            hintText: 'e.g. 25',
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 14),

          // Reason selector
          const Text('Reason for Adjustment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _reasonCtrl.text,
            items: _presetReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _reasonCtrl.text = val);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),

          const SizedBox(height: 14),

          CustomTextField(
            label: 'Audit Notes (Optional)',
            hintText: 'e.g. Batch #401 from supplier ABC',
            controller: _notesCtrl,
          ),

          const SizedBox(height: 20),

          CustomButton(
            text: 'APPLY STOCK ADJUSTMENT',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _submitAdjustment,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(StockAdjustmentType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            if (type == StockAdjustmentType.stockOut) {
              _reasonCtrl.text = 'Inventory Damage';
            } else if (type == StockAdjustmentType.stockIn) {
              _reasonCtrl.text = 'Purchase / Restock';
            } else {
              _reasonCtrl.text = 'Physical Audit Count Discrepancy';
            }
          });
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.canvas,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : AppColors.secondaryText),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
