import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class BatchAddItemsModal extends StatefulWidget {
  const BatchAddItemsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BatchAddItemsModal(),
    );
  }

  @override
  State<BatchAddItemsModal> createState() => _BatchAddItemsModalState();
}

class _BatchAddItemsModalState extends State<BatchAddItemsModal> {
  final Map<String, double> _selectedQuantities = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Pre-populate with currently existing quantities from cart
    final billing = context.read<BillingProvider>();
    for (final item in billing.cartItems) {
      _selectedQuantities[item.product.id] = item.quantity;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _increment(Product product) {
    setState(() {
      final current = _selectedQuantities[product.id] ?? 0.0;
      _selectedQuantities[product.id] = current + 1.0;
    });
  }

  void _decrement(Product product) {
    setState(() {
      final current = _selectedQuantities[product.id] ?? 0.0;
      if (current > 1.0) {
        _selectedQuantities[product.id] = current - 1.0;
      } else {
        _selectedQuantities.remove(product.id);
      }
    });
  }

  void _addAllToCart() {
    final billing = context.read<BillingProvider>();
    final allProducts = billing.products;

    for (final entry in _selectedQuantities.entries) {
      final prod = allProducts.where((p) => p.id == entry.key).firstOrNull;
      if (prod != null) {
        billing.addMultipleToCart(prod, entry.value);
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated ${_selectedQuantities.length} items in cart!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final allProducts = billing.products;
    final categories = billing.categories;

    final filteredProducts = allProducts.where((p) {
      final matchesCat = _selectedCategory == 'all' || p.categoryId == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    int totalSelectedCount = 0;
    double totalBatchAmount = 0.0;
    for (final entry in _selectedQuantities.entries) {
      final prod = allProducts.where((p) => p.id == entry.key).firstOrNull;
      if (prod != null) {
        totalSelectedCount += entry.value.toInt();
        totalBatchAmount += prod.sellingPrice * entry.value;
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.90).clamp(360.0, 750.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Multi-Item Quick Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
                    ),
                    Text(
                      'Set quantities for multiple items and add all at once',
                      style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // Search and Category Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'Search items to add in bulk...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('all', 'All Items'),
                ...categories.map((c) => _buildCategoryChip(c.id, c.name)),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Products List with Steppers
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('No matching items found', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final qty = _selectedQuantities[product.id] ?? 0.0;
                      final isSelected = qty > 0;
                      final hasImage = product.imagePath != null &&
                          product.imagePath!.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CustomCard(
                          onTap: () => _increment(product),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          borderSide: isSelected
                              ? const BorderSide(color: AppColors.primaryBlue, width: 1.5)
                              : const BorderSide(color: AppColors.border),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                        : AppColors.canvas,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: hasImage
                                      ? Image.file(
                                          File(product.imagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.restaurant_menu,
                                            color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                                            size: 18,
                                          ),
                                        )
                                      : Icon(
                                          Icons.restaurant_menu,
                                          color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                                          size: 18,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(product.sellingPrice)} • ${product.categoryName}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                // Active Stepper
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 24),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _decrement(product),
                                    ),
                                    Container(
                                      width: 38,
                                      height: 30,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.canvas,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.primaryBlue),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${qty.toInt()}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 24),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _increment(product),
                                    ),
                                  ],
                                )
                              else
                                // Quick Add button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    foregroundColor: AppColors.primaryBlue,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(60, 32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _increment(product),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNavy.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalSelectedCount items selected',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                      ),
                      Text(
                        CurrencyFormatter.format(totalBatchAmount),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.accentNavy),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'ADD ALL TO CART',
                    icon: Icons.check,
                    width: 180,
                    height: 42,
                    onPressed: _selectedQuantities.isNotEmpty ? _addAllToCart : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = id),
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.canvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.accentNavy,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }
}
