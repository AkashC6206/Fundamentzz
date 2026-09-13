import '../../../core/services/bluetooth_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_card.dart';
import '../help/about_view.dart';
import '../help/help_faq_view.dart';
import 'backup_restore_view.dart';
import 'bill_customizer_view.dart';
import 'business_profile_view.dart';
import 'printer_setup_view.dart';
import 'tax_settings_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Settings & Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Configuration Section (One-Time Setup & AppData Storage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Store Configuration (AppData)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PERMANENT STORAGE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.storefront,
                    iconColor: AppColors.primaryBlue,
                    title: 'Business Profile & Store Info',
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ONE-TIME SETUP',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ),
                    subtitle: 'Restaurant name, address, GSTIN, UPI ID (Permanently saved in AppData)',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessProfileView())),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.receipt,
                    iconColor: AppColors.info,
                    title: 'Tax & Service Charges',
                    subtitle: 'GST/VAT rates, tax-inclusive mode, round-off (Saved in AppData)',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaxSettingsView())),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.tune,
                    iconColor: AppColors.primaryBlue,
                    title: 'Bill & Receipt Customizer',
                    subtitle: 'Toggle what details & notes are printed on bills (Saved in AppData)',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BillCustomizerView())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hardware & Backup Section
            const Text(
              'Hardware & Data Management',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      final activePrinter = settings.selectedPrinter;
                      final isConnected = settings.connectionState == PrinterConnectionState.connected;
                      final printerName = activePrinter?.name ?? settings.savedPrinterName;

                      return ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSetupView())),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isConnected ? AppColors.success : AppColors.primaryBlueDark).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                          ),
                          child: Icon(
                            Icons.print,
                            color: isConnected ? AppColors.success : AppColors.primaryBlueDark,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            const Text(
                              'Bluetooth Printer',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                            ),
                            if (isConnected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'CONNECTED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          isConnected
                              ? '$printerName (${activePrinter?.paperSize ?? settings.selectedPaperSize})'
                              : (printerName != null ? 'Saved: $printerName (Tap to Connect)' : 'Pair 58mm/80mm ESC/POS wireless receipt printers'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isConnected ? AppColors.accentNavy : AppColors.secondaryText,
                            fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settings.isScanningPrinters)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20, color: AppColors.primaryBlue),
                                tooltip: 'Refresh / Auto-Connect',
                                onPressed: () => settings.refreshPrinters(),
                              ),
                            IconButton(
                              icon: const Icon(Icons.settings_bluetooth, size: 20, color: AppColors.secondaryText),
                              tooltip: 'Open Phone Bluetooth Settings',
                              onPressed: () => settings.openSystemBluetoothSettings(),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.metallicSilver, size: 20),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.cloud_sync,
                    iconColor: AppColors.success,
                    title: 'Backup, Export & Demo Data',
                    subtitle: 'Export local DB snapshots, load sample demo data, or reset',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupRestoreView())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Support & About Section
            const Text(
              'Support & Information',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.help_outline,
                    iconColor: AppColors.warning,
                    title: 'How to Use & FAQs',
                    subtitle: 'Quick tips, POS shortcuts, and operational guides',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpFaqView())),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline,
                    iconColor: AppColors.accentNavy,
                    title: 'About Fundamentzz',
                    subtitle: '${AppStrings.appName} ${AppStrings.appVersion}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutView())),
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

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            badge,
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.metallicSilver, size: 20),
    );
  }
}
