import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/custom_card.dart';
import 'add_edit_product_view.dart';
import 'category_manager_view.dart';
import 'widgets/menu_import_dialog.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/menu_transfer_service.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  void _openAddProduct([Product? product]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddEditProductView(product: product)),
    ).then((_) {
      if (mounted) {
        context.read<BillingProvider>().refreshCatalogue();
      }
    });
  }

  void _openCategoryManager() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CategoryManagerView()),
    ).then((_) {
      if (mounted) {
        context.read<BillingProvider>().loadCategories();
      }
    });
  }

  Future<void> _exportMenu() async {
    final transferService = sl<MenuTransferService>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating menu export ZIP...'),
        duration: Duration(milliseconds: 1000),
      ),
    );

    final res = await transferService.exportMenuToZip();

    if (!mounted) return;

    if (res.isSuccess) {
      final export = res.data!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Menu exported: ${export.productsCount} items, ${export.imagesCount} images.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failure?.message ?? 'Failed to export menu'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _importMenu() async {
    final transferService = sl<MenuTransferService>();
    final inspectRes = await transferService.pickAndInspectMenuZip();

    if (!mounted) return;

    if (!inspectRes.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inspectRes.failure?.message ?? 'Error reading menu backup ZIP'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final inspection = inspectRes.data;
    if (inspection == null) {
      // User cancelled picker
      return;
    }

    // Show confirmation dialog (replace vs merge)
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MenuImportDialog(
        inspection: inspection,
        onConfirm: ({required bool replaceExisting}) async {
          final applyRes = await transferService.applyMenuImport(
            inspection: inspection,
            replaceExisting: replaceExisting,
          );

          if (applyRes.isSuccess) {
            final summary = applyRes.data!;
            if (mounted) {
              final inv = context.read<InventoryProvider>();
              final billing = context.read<BillingProvider>();
              final messenger = ScaffoldMessenger.of(context);

              await inv.init();
              await billing.refreshCatalogue();
              await billing.loadCategories();

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ Successfully imported ${summary.productsImported} products, ${summary.categoriesImported} categories, and ${summary.imagesRestored} images.',
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            throw Exception(applyRes.failure?.message ?? 'Failed to apply import');
          }
        },
      ),
    );

    if (confirmed == true && mounted) {
      context.read<InventoryProvider>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();
    final products = invProv.products;
    final categories = invProv.categories;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Inventory Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: AppColors.accentNavy),
            tooltip: 'Manage Categories',
            onPressed: _openCategoryManager,
          ),
          IconButton(
            icon: const Icon(Icons.add_box, color: AppColors.primaryBlue),
            tooltip: 'Add New Product',
            onPressed: () => _openAddProduct(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.accentNavy),
            tooltip: 'Menu Import / Export',
            onSelected: (val) {
              if (val == 'export') _exportMenu();
              if (val == 'import') _importMenu();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 10),
                    Text('Export Menu (.zip)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download_for_offline, size: 20, color: AppColors.success),
                    SizedBox(width: 10),
                    Text('Import Menu (.zip)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Header Search & Category Filter
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  children: [
                    AppSearchBar(
                      controller: _searchCtrl,
                      hintText: 'Search products by name or SKU...',
                      onChanged: (val) => invProv.search(val),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip(
                            id: 'all',
                            label: 'All (${invProv.totalProductCount})',
                            isSelected: invProv.selectedCategoryId == 'all',
                            onTap: () => invProv.selectCategory('all'),
                          ),
                          ...categories.map((cat) {
                            return _buildCategoryChip(
                              id: cat.id,
                              label: cat.name,
                              isSelected: invProv.selectedCategoryId == cat.id,
                              onTap: () => invProv.selectCategory(cat.id),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Products Count Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.canvas,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${products.length} Products listed',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                    ),
                    Text(
                      '${categories.length} Categories',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Products List
              Expanded(
                child: invProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Products in Inventory',
                            message: 'Add food items, beverages, and ingredients to build your catalogue.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: products.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _buildProductListItem(product);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddProduct(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
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

  Widget _buildProductListItem(Product product) {
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;

    return CustomCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Dish Photo / Icon avatar
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
                      File(product.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 22),
                    )
                  : const Icon(Icons.restaurant_menu, color: AppColors.primaryBlue, size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      product.categoryName,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                    if (product.barcode.isNotEmpty) ...[
                      const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      Text('SKU: ${product.barcode}', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.sellingPrice),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.secondaryText),
            onSelected: (val) {
              if (val == 'edit') {
                _openAddProduct(product);
              } else if (val == 'delete') {
                _confirmDeleteProduct(product);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.accentNavy),
                    SizedBox(width: 8),
                    Text('Edit Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "${product.name}" from catalogue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<InventoryProvider>().deleteProduct(product.id);
              if (mounted) {
                context.read<BillingProvider>().refreshCatalogue();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
