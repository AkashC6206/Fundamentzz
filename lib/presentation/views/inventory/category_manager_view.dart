import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';

class CategoryManagerView extends StatelessWidget {
  const CategoryManagerView({super.key});

  void _showAddEditCategoryDialog(BuildContext context, [Category? category]) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category != null ? 'Edit Category' : 'New Category', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Category Name *',
              hintText: 'e.g. Biryanis & Rice, Mocktails',
              controller: nameCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final inv = context.read<InventoryProvider>();
              final cat = Category(
                id: category?.id ?? const Uuid().v4(),
                name: nameCtrl.text.trim(),
              );
              await inv.saveCategory(cat);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();
    final categories = invProv.categories;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryBlue),
            tooltip: 'Add Category',
            onPressed: () => _showAddEditCategoryDialog(context),
          ),
        ],
      ),
      body: categories.isEmpty
          ? AppEmptyState(
              icon: Icons.category_outlined,
              title: 'No Categories Created',
              message: 'Organize your restaurant menu items into logical groups.',
              actionText: 'Create Category',
              onAction: () => _showAddEditCategoryDialog(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final productCount = invProv.products.where((p) => p.categoryId == cat.id).length;

                return CustomCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant, color: AppColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$productCount items in this category',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.secondaryText, size: 20),
                        onPressed: () => _showAddEditCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        onPressed: () {
                          _confirmDelete(context, cat);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            text: 'ADD NEW CATEGORY',
            icon: Icons.add,
            onPressed: () => _showAddEditCategoryDialog(context),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<InventoryProvider>().deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
