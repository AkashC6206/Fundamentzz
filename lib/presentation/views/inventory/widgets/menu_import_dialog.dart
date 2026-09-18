import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/services/menu_transfer_service.dart';

class MenuImportDialog extends StatefulWidget {
  final MenuInspectionResult inspection;
  final Future<void> Function({required bool replaceExisting}) onConfirm;

  const MenuImportDialog({
    super.key,
    required this.inspection,
    required this.onConfirm,
  });

  @override
  State<MenuImportDialog> createState() => _MenuImportDialogState();
}

class _MenuImportDialogState extends State<MenuImportDialog> {
  bool _replaceExisting = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to replace if existing DB has data, but user can choose merge
    _replaceExisting = widget.inspection.dbHasExistingData;
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(replaceExisting: _replaceExisting);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insp = widget.inspection;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.file_download_outlined, color: AppColors.primaryBlue),
          SizedBox(width: 10),
          Text(
            'Import Menu Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card of incoming ZIP contents
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Categories to import:', '${insp.categoriesCount}'),
                    const SizedBox(height: 4),
                    _buildStatRow('Products to import:', '${insp.productsCount}'),
                    const SizedBox(height: 4),
                    _buildStatRow('Dish images found:', '${insp.imagesCount}'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (insp.dbHasExistingData) ...[
                // Warning badge for existing data
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your app already has ${insp.currentDbProductsCount} products across ${insp.currentDbCategoriesCount} categories. Choose how you want to proceed:',
                          style: const TextStyle(fontSize: 12, color: AppColors.accentNavy, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Replacement vs Merge options
                InkWell(
                  onTap: _isProcessing ? null : () => setState(() => _replaceExisting = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _replaceExisting ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _replaceExisting ? AppColors.primaryBlue : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _replaceExisting,
                          activeColor: AppColors.primaryBlue,
                          onChanged: _isProcessing ? null : (v) => setState(() => _replaceExisting = v!),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Replace Current Menu',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                              ),
                              Text(
                                'Erases existing categories and products before importing.',
                                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _isProcessing ? null : () => setState(() => _replaceExisting = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_replaceExisting ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_replaceExisting ? AppColors.primaryBlue : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _replaceExisting,
                          activeColor: AppColors.primaryBlue,
                          onChanged: _isProcessing ? null : (v) => setState(() => _replaceExisting = v!),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Merge with Current Menu',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                              ),
                              Text(
                                'Adds new items and updates matching IDs without deleting existing items.',
                                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Your current menu is empty. All imported categories, products, and dish images will be populated directly into your catalog.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.35),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
              ],

              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 8),
                      Text('Unpacking and restoring menu...', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _replaceExisting && insp.dbHasExistingData ? AppColors.danger : AppColors.primaryBlue,
          ),
          onPressed: _isProcessing ? null : _handleConfirm,
          child: Text(
            _replaceExisting && insp.dbHasExistingData ? 'Replace Menu' : 'Import Menu',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
      ],
    );
  }
}
