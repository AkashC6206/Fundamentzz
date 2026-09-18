import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/menu_transfer_service.dart';
import '../inventory/widgets/menu_import_dialog.dart';

class BackupRestoreView extends StatefulWidget {
  const BackupRestoreView({super.key});

  @override
  State<BackupRestoreView> createState() => _BackupRestoreViewState();
}

class _BackupRestoreViewState extends State<BackupRestoreView> {
  bool _isExporting = false;
  bool _isResetting = false;
  bool _isMenuExporting = false;
  bool _isMenuImporting = false;

  Future<void> _exportMenuZip() async {
    setState(() => _isMenuExporting = true);
    final transferService = sl<MenuTransferService>();
    final res = await transferService.exportMenuToZip();
    setState(() => _isMenuExporting = false);

    if (mounted) {
      if (res.isSuccess) {
        final exp = res.data!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Menu exported: ${exp.productsCount} products, ${exp.imagesCount} images.'),
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
  }

  Future<void> _importMenuZip() async {
    setState(() => _isMenuImporting = true);
    final transferService = sl<MenuTransferService>();
    final inspectRes = await transferService.pickAndInspectMenuZip();
    setState(() => _isMenuImporting = false);

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
    if (inspection == null) return;

    await showDialog<bool>(
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
              final messenger = ScaffoldMessenger.of(context);
              await _refreshAllProviders();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ Menu imported: ${summary.productsImported} products, ${summary.imagesRestored} images restored.',
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            throw Exception(applyRes.failure?.message ?? 'Failed to import menu');
          }
        },
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    final settings = context.read<SettingsProvider>();
    final res = await settings.exportAndShareBackup();
    setState(() => _isExporting = false);

    if (mounted) {
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup JSON exported successfully!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.failure?.message ?? 'Failed to export backup'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _loadSampleData() async {
    setState(() => _isResetting = true);
    final settings = context.read<SettingsProvider>();
    final res = await settings.loadSampleData();

    if (mounted) {
      await _refreshAllProviders();
    }

    setState(() => _isResetting = false);

    if (mounted) {
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample Restaurant Demo Data Loaded!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Database Data?', style: TextStyle(color: AppColors.danger)),
        content: const Text(
          'This will permanently delete all products, invoices, customer credit records, and expense logs from local storage. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isResetting = true);
              final settings = context.read<SettingsProvider>();
              await settings.resetDatabase();
              if (mounted) {
                await _refreshAllProviders();
              }
              setState(() => _isResetting = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared successfully.'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Reset All Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllProviders() async {
    if (!mounted) return;
    final billing = context.read<BillingProvider>();
    final inventory = context.read<InventoryProvider>();
    final expense = context.read<ExpenseProvider>();
    final sales = context.read<SalesHistoryProvider>();
    final analytics = context.read<AnalyticsProvider>();

    await billing.init();
    await inventory.init();
    await expense.init();
    await sales.loadSales();
    await analytics.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Backup & Data Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          children: [
            // Backup & Export Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Export Database Snapshot',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export your complete offline catalogue, sales history, customer ledgers, and expense logs as a JSON backup file. You can share it to Google Drive, WhatsApp, or Email.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'EXPORT & SHARE BACKUP (JSON)',
                    icon: Icons.share,
                    isLoading: _isExporting,
                    onPressed: _exportBackup,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Catalogue Export & Import Card (ZIP)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.folder_zip_outlined, color: AppColors.primaryBlue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Menu Catalogue Export & Import (ZIP)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export your food & drink categories, product items, prices, and dish photos into a single ZIP archive. You can easily share it or restore it onto any terminal.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'EXPORT MENU',
                          icon: Icons.upload_file,
                          isLoading: _isMenuExporting,
                          onPressed: _exportMenuZip,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'IMPORT MENU',
                          icon: Icons.download_for_offline,
                          variant: ButtonVariant.secondary,
                          isLoading: _isMenuImporting,
                          onPressed: _importMenuZip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Demo Data Seeder Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant_menu, color: AppColors.info, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Populate Restaurant Demo Data',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Populate complete restaurant sample data including 12 food/drink products across 5 categories, 8 past orders with trend charts, sample customers with Udhaar, and operating expenses for instant testing.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'LOAD RESTAURANT DEMO DATA',
                    icon: Icons.playlist_add_check,
                    variant: ButtonVariant.secondary,
                    isLoading: _isResetting,
                    onPressed: _loadSampleData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Clear Data Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.delete_forever, color: AppColors.danger, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Clear Local Database / Reset App',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Erase all local transaction logs, product records, and customer accounts to start with a fresh clean database.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'RESET ALL DATABASE DATA',
                    icon: Icons.delete_outline,
                    variant: ButtonVariant.danger,
                    isLoading: _isResetting,
                    onPressed: _resetAllData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
