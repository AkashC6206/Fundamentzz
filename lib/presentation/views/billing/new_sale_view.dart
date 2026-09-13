import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/custom_card.dart';
import '../inventory/add_edit_product_view.dart';
import 'cart_summary_sheet.dart';
import 'held_bills_dialog.dart';
import 'pos_quick_quantity_dialog.dart';

class NewSaleView extends StatefulWidget {
  const NewSaleView({super.key});

  @override
  State<NewSaleView> createState() => _NewSaleViewState();
}

class _NewSaleViewState extends State<NewSaleView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditProductView()),
    ).then((_) {
      if (mounted) {
        context.read<BillingProvider>().refreshCatalogue();
      }
    });
  }

  void _confirmClearCart(BuildContext context, BillingProvider billing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from the current order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              billing.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final products = billing.products;
    final categories = billing.categories;
    final selectedCategoryId = billing.selectedCategoryId;
    final heldBillsCount = billing.heldBills.length;
    final isLoading = billing.isLoading;
    final hasCartItems = billing.cartItems.isNotEmpty;

    debugPrint('[UI] NewSaleView build: billing.products.length = ${products.length}, isLoading = $isLoading, error = ${billing.errorMessage}');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POS Quick Billing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(
              hasCartItems
                  ? '${billing.cartItems.length} items • ${billing.totalCartItemCount} units'
                  : 'Tap items to add quickly',
              style: TextStyle(
                fontSize: 11,
                color: hasCartItems ? AppColors.primaryBlue : AppColors.secondaryText,
                fontWeight: hasCartItems ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Clear Cart shortcut if items exist
          if (hasCartItems)
            IconButton(
              icon: const Icon(Icons.remove_shopping_cart_outlined, color: AppColors.danger),
              tooltip: 'Clear Cart',
              onPressed: () => _confirmClearCart(context, billing),
            ),
          // Add Dish
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue),
            tooltip: 'Add Dish to Menu',
            onPressed: _openAddProduct,
          ),
          // Held Bills
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.pause_circle_outline, color: AppColors.accentNavy),
                if (heldBillsCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$heldBillsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Held Bills',
            onPressed: () => HeldBillsDialog.show(context),
          ),
          // Cart Drawer Shortcut
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryBlue),
                if (hasCartItems)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${billing.totalCartItemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'View Cart',
            onPressed: () => CartSummarySheet.show(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;

          final catalogueSection = Column(
            children: [
              // Search Bar
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        controller: _searchCtrl,
                        hintText: 'Search menu items by name...',
                        onChanged: (val) => context.read<BillingProvider>().searchProducts(val),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.secondaryText),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<BillingProvider>().searchProducts('');
                          setState(() {});
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Category Filter Pills
              if (categories.isNotEmpty)
                Container(
                  height: 46,
                  color: AppColors.surface,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      _buildCategoryPill(
                        id: 'all',
                        name: 'All Items',
                        isSelected: selectedCategoryId == 'all',
                        onTap: () => context.read<BillingProvider>().selectCategory('all'),
                      ),
                      ...categories.map((cat) {
                        return _buildCategoryPill(
                          id: cat.id,
                          name: cat.name,
                          isSelected: selectedCategoryId == cat.id,
                          onTap: () => context.read<BillingProvider>().selectCategory(cat.id),
                        );
                      }),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Multi-Item Quick Order Catalog List
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: isLoading && products.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.primaryBlue),
                            )
                          : billing.errorMessage != null && products.isEmpty
                              ? RefreshIndicator(
                                  onRefresh: () => context.read<BillingProvider>().refreshCatalogue(),
                                  child: ListView(
                                    children: [
                                      const SizedBox(height: 40),
                                      AppEmptyState(
                                        icon: Icons.error_outline,
                                        title: 'Error Loading Products',
                                        message: billing.errorMessage ?? 'Failed to load products',
                                      ),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.read<BillingProvider>().refreshCatalogue(),
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: const Text('Retry Loading Menu', style: TextStyle(fontWeight: FontWeight.w700)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : products.isEmpty
                                  ? RefreshIndicator(
                                  onRefresh: () => context.read<BillingProvider>().refreshCatalogue(),
                                  child: ListView(
                                    children: [
                                      const SizedBox(height: 40),
                                      const AppEmptyState(
                                        icon: Icons.search_off,
                                        title: 'No Menu Items Found',
                                        message: 'Tap below to add your dishes or products.',
                                      ),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: _openAddProduct,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Dish to Menu', style: TextStyle(fontWeight: FontWeight.w700)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => context.read<BillingProvider>().refreshCatalogue(),
                                  child: GridView.builder(
                                    padding: EdgeInsets.only(
                                      left: 12,
                                      top: 10,
                                      right: 12,
                                      bottom: isWide ? 20 : 85,
                                    ),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: isWide ? 216 : 212,
                                    ),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      final inCart = billing.cartItems
                                          .where((i) => i.product.id == product.id)
                                          .firstOrNull;
                                      final qty = inCart?.quantity ?? 0.0;

                                      return QuickOrderItemTile(
                                        key: ValueKey(product.id),
                                        product: product,
                                        quantityInCart: qty,
                                        onAddToCart: () => billing.addToCart(product),
                                        onDecrement: () => billing.decrementFromCart(product.id),
                                        onSetQuantity: (newQty) {
                                          billing.setCartItemQuantity(product, newQty);
                                        },
                                      );
                                    },
                                  ),
                                ),
                    ),

                    // Floating Bottom Checkout Pill Button (Mobile)
                    if (!isWide)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (hasCartItems) {
                                CartSummarySheet.show(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cart is empty. Tap items above to add!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.38),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Checkout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        hasCartItems
                                            ? CurrencyFormatter.format(billing.cartTotals.grandTotal)
                                            : '0.0',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: catalogueSection),
                SizedBox(
                  width: (constraints.maxWidth * 0.38).clamp(320.0, 440.0),
                  child: const CartSummaryContent(isEmbedded: true),
                ),
              ],
            );
          }

          return catalogueSection;
        },
      ),
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.canvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.accentNavy,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.border),
        ),
        showCheckmark: false,
      ),
    );
  }
}

/// A modern, responsive 2-column POS Product Grid Card with picture/placeholder, name, price, and instant touch controls
class QuickOrderItemTile extends StatelessWidget {
  final Product product;
  final double quantityInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onDecrement;
  final ValueChanged<double> onSetQuantity;

  const QuickOrderItemTile({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.onAddToCart,
    required this.onDecrement,
    required this.onSetQuantity,
  });

  void _openBulkQuantityDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    PosQuickQuantityDialog.show(
      context,
      product: product,
      currentQuantity: quantityInCart,
      onQuantitySelected: onSetQuantity,
    );
  }

  Widget _buildPlaceholder(bool isSelected) {
    return Container(
      width: double.infinity,
      color: isSelected
          ? AppColors.primaryBlue.withValues(alpha: 0.08)
          : const Color(0xFFF7F8FA),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: isSelected ? AppColors.primaryBlue : const Color(0xFF5A6679),
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = quantityInCart > 0;
    final hasImage = !kIsWeb &&
        product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        product.imagePath != 'null' &&
        File(product.imagePath!).existsSync();
    final lineTotal = product.sellingPrice * quantityInCart;
    final qtyDisplay = quantityInCart % 1 == 0
        ? quantityInCart.toInt().toString()
        : quantityInCart.toString();

    return CustomCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onAddToCart();
      },
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      borderRadius: 14,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
      borderSide: isSelected
          ? const BorderSide(color: AppColors.primaryBlue, width: 2.0)
          : BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Picture if available, otherwise stylish food placeholder
          SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasImage
                    ? Image.file(
                        File(product.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(isSelected),
                      )
                    : _buildPlaceholder(isSelected),

                // Cart Quantity Badge (Top-Right)
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${qtyDisplay}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                // Category Tag (Top-Left)
                if (product.categoryName.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Product Name, Price, and Touch Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dish Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentNavy,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Selling Price & Line Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (isSelected)
                      Flexible(
                        child: Text(
                          'Line Total: ${CurrencyFormatter.format(lineTotal)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Instant Controls (Add or - / Qty / +)
                if (isSelected)
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onDecrement();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _openBulkQuantityDialog(context),
                            child: Center(
                              child: Text(
                                qtyDisplay,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onAddToCart();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.add_circle, color: AppColors.primaryBlue, size: 20),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 15, color: AppColors.primaryBlue),
                        SizedBox(width: 4),
                        Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

