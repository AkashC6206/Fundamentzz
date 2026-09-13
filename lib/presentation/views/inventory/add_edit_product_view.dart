import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/image_service.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditProductView extends StatefulWidget {
  final Product? product;

  const AddEditProductView({super.key, this.product});

  @override
  State<AddEditProductView> createState() => _AddEditProductViewState();
}

class _AddEditProductViewState extends State<AddEditProductView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _taxRateCtrl;

  String? _selectedCategoryId;
  String _selectedUnit = 'portion';
  bool _isAvailable = true;
  bool _isSaving = false;
  bool _isCompressingImage = false;

  String? _imagePath;
  String? _imageCompressionInfo;
  int _selectedColorValue = 0xFF1E5FDE;

  final List<String> _units = ['portion', 'plate', 'pcs', 'glass', 'bowl', 'pot', 'kg', 'ltr', 'serving'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _sellingPriceCtrl = TextEditingController(text: p != null ? p.sellingPrice.toString() : '');
    _costPriceCtrl = TextEditingController(text: p != null ? p.costPrice.toString() : '0');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _taxRateCtrl = TextEditingController(text: p != null ? p.taxRate.toString() : '5.0');

    _selectedCategoryId = p?.categoryId;
    _selectedUnit = p?.unit ?? 'portion';
    _isAvailable = p?.isAvailable ?? true;
    _imagePath = p?.imagePath;
    _selectedColorValue = p?.colorValue ?? 0xFF1E5FDE;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _barcodeCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() => _isCompressingImage = true);
    final imageService = sl<ImageService>();
    final result = await imageService.pickAndCompressImage(
      source: source,
      maxDimension: 800,
      quality: 80,
    );

    setState(() => _isCompressingImage = false);

    if (result != null) {
      setState(() {
        _imagePath = result.filePath;
        _imageCompressionInfo = 'Compressed: ${result.formattedCompressedSize} (${result.savingsPercent} saved)';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Image compressed to ${result.formattedCompressedSize}!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Dish / Product Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
              ),
              const SizedBox(height: 4),
              const Text(
                'Images are automatically compressed & optimized for rapid POS display.',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndProcessImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.primaryBlue, size: 30),
                            SizedBox(height: 8),
                            Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accentNavy)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndProcessImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library, color: AppColors.primaryBlue, size: 30),
                            SizedBox(height: 8),
                            Text('From Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accentNavy)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _imagePath = null;
                        _imageCompressionInfo = null;
                      });
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                    label: const Text('Remove Photo', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final catNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accentNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Category Name',
              hintText: 'e.g. Specials, Shakes, Pizzas',
              controller: catNameCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              final name = catNameCtrl.text.trim();
              if (name.isEmpty) return;
              final invProv = context.read<InventoryProvider>();
              final newCat = Category(
                id: const Uuid().v4(),
                name: name,
                icon: 'restaurant_menu',
                colorValue: 0xFF1E5FDE,
              );
              Navigator.pop(ctx);
              await invProv.saveCategory(newCat);
              if (mounted) {
                context.read<BillingProvider>().loadCategories();
                setState(() {
                  _selectedCategoryId = newCat.id;
                });
              }
            },
            child: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least a Product Name and Selling Price.'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final invProv = context.read<InventoryProvider>();
      List<Category> categories = invProv.categories;
      if (categories.isEmpty) {
        await invProv.loadCategories();
        categories = invProv.categories;
      }

      String catId;
      String catName;

      if (categories.isEmpty) {
        // Auto-create a General category if none exist
        final defaultCat = Category(
          id: const Uuid().v4(),
          name: 'General',
          icon: 'restaurant_menu',
          colorValue: 0xFF1E5FDE,
        );
        await invProv.saveCategory(defaultCat);
        catId = defaultCat.id;
        catName = defaultCat.name;
      } else {
        catId = _selectedCategoryId ?? categories.first.id;
        final matchedCat = categories.where((c) => c.id == catId).firstOrNull;
        if (matchedCat != null) {
          catName = matchedCat.name;
        } else {
          catId = categories.first.id;
          catName = categories.first.name;
        }
      }

      final sellingPrice = double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0.0;
      final costPrice = double.tryParse(_costPriceCtrl.text.trim()) ?? 0.0;
      final stockQty = widget.product?.stockQuantity ?? 999999.0;
      const lowStockAlert = 0.0;
      final taxRate = double.tryParse(_taxRateCtrl.text.trim()) ?? 5.0;

      final product = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        categoryId: catId,
        categoryName: catName,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        stockQuantity: stockQty,
        lowStockThreshold: lowStockAlert,
        unit: _selectedUnit,
        barcode: _barcodeCtrl.text.trim(),
        imagePath: _imagePath,
        colorValue: _selectedColorValue,
        taxRate: taxRate,
        isAvailable: _isAvailable,
      );

      final res = await invProv.saveProduct(product);

      if (!mounted) return;

      if (res.isSuccess) {
        // Synchronize BillingProvider immediately so Catalogue displays the new product
        await context.read<BillingProvider>().refreshCatalogue();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.product != null ? 'Product updated successfully!' : 'Product "${product.name}" added to catalogue!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: ${res.failure?.message ?? "Database error"}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Error saving product: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();
    final categories = invProv.categories;
    final isEditing = widget.product != null;

    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dish Image Upload Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dish Picture / Photo',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                        ),
                        if (_isCompressingImage)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (hasImage)
                      // Photo Preview Card
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: AppColors.canvas,
                              child: Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, size: 40, color: AppColors.secondaryText),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _imageCompressionInfo ?? 'Optimized Format',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showImagePickerOptions,
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Change', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _imagePath = null;
                                      _imageCompressionInfo = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 14),
                                  label: const Text('Remove', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.danger,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Empty Upload Placeholder
                      InkWell(
                        onTap: _showImagePickerOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(alpha: 0.4),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: 28),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to Add Dish Picture',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Camera / Gallery • Auto-compressed to lightweight format',
                                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Basic Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Basic Product Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Item / Product Name *',
                      hintText: 'e.g. Crispy Butter Chicken',
                      controller: _nameCtrl,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a product name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown with + Add Category button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
                        InkWell(
                          onTap: _showAddCategoryDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 14, color: AppColors.primaryBlue),
                                SizedBox(width: 2),
                                Text('New Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('cat_${_selectedCategoryId}_${categories.length}'),
                      value: (categories.any((c) => c.id == _selectedCategoryId))
                          ? _selectedCategoryId
                          : (categories.isNotEmpty ? categories.first.id : null),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Unit Selector
                    const Text('Unit of Measure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('unit_$_selectedUnit'),
                      value: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pricing & Tax Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing & Taxation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Selling Price (₹) *',
                            hintText: 'e.g. 350',
                            controller: _sellingPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Cost Price (₹)',
                            hintText: 'e.g. 150',
                            controller: _costPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Applicable Tax Rate (%)',
                      hintText: 'e.g. 5.0 (for 5% GST)',
                      controller: _taxRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Optional Product Code / SKU Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Code / SKU (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Item Code / SKU',
                      hintText: 'e.g. SKU-101',
                      controller: _barcodeCtrl,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: isEditing ? 'UPDATE PRODUCT' : 'SAVE PRODUCT TO CATALOGUE',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveProduct,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
