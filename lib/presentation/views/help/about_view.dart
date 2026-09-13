import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/custom_card.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('About Fundamentzz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo and branding
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.appTagline,
                    style: TextStyle(fontSize: 13, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Version ${AppStrings.appVersion}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Built for High-Speed Food & Beverage Operations',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fundamentzz is a full-featured, offline-first restaurant billing and point-of-sale management system crafted for cafes, quick-service eateries, bistros, bakeries, and cloud kitchens.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Core System Capabilities:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                  ),
                  SizedBox(height: 6),
                  Text('• 100% Offline SQLite Architecture\n• Multi-Category Visual Catalogue\n• Hold & Resume Multi-Table Billing\n• Cash, UPI QR, Card & Customer Udhaar\n• Thermal Receipt Printing (ESC/POS 58mm/80mm) & PDF Sharing\n• Real-Time Low Stock & Profit & Loss Analytics\n• Customer Khata / Ledger with Settlement Tracking\n• JSON Backup Snapshot & Restore',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                '© 2026 Fundamentzz POS. All Rights Reserved.',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
