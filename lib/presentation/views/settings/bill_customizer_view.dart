import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../domain/entities/bill_customizer_settings.dart';
import '../../../domain/entities/business_profile.dart';
import '../../../domain/entities/tax_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/custom_card.dart';

class BillCustomizerView extends StatefulWidget {
  const BillCustomizerView({super.key});

  @override
  State<BillCustomizerView> createState() => _BillCustomizerViewState();
}

class _BillCustomizerViewState extends State<BillCustomizerView> {
  bool _isPreviewExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Bill & Receipt Customizer'),
        actions: [
          TextButton.icon(
            icon: Icon(
              _isPreviewExpanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: AppColors.primaryBlue,
            ),
            label: Text(
              _isPreviewExpanded ? 'Hide Preview' : 'Show Preview',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
            ),
            onPressed: () => setState(() => _isPreviewExpanded = !_isPreviewExpanded),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final cfg = settings.billCustomizerSettings;
          final profile = settings.businessProfile;
          final taxSettings = settings.taxSettings;

          void update(BillCustomizerSettings Function(BillCustomizerSettings) updater) {
            final next = updater(cfg);
            settings.updateBillCustomizerSettings(next);
          }

          return ListView(
            padding: const EdgeInsets.all(AppDimens.p16),
            children: [
              // Info Callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tune, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Bill & Thermal Receipts',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Toggle elements on or off. The live preview, on-screen bill, PDF receipts, and thermal printer will strictly follow your choices.',
                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- LIVE BILL PREVIEW ---
              if (_isPreviewExpanded) ...[
                _buildLivePreviewCard(cfg, profile, taxSettings),
                const SizedBox(height: 20),
              ],

              // 1. Business & Header Info
              const Text(
                'Store & Header Information',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.store,
                      title: 'Business / Restaurant Name',
                      subtitle: 'Print ${profile.restaurantName.isNotEmpty ? profile.restaurantName : "store name"}',
                      value: cfg.showBusinessName,
                      onChanged: (val) => update((c) => c.copyWith(showBusinessName: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.format_quote,
                      title: 'Tagline / Slogan',
                      subtitle: 'Print restaurant tagline below store name',
                      value: cfg.showTagline,
                      onChanged: (val) => update((c) => c.copyWith(showTagline: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.location_on_outlined,
                      title: 'Store Address',
                      subtitle: 'Print location and address lines',
                      value: cfg.showAddress,
                      onChanged: (val) => update((c) => c.copyWith(showAddress: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: 'Print contact phone number',
                      value: cfg.showPhone,
                      onChanged: (val) => update((c) => c.copyWith(showPhone: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.badge_outlined,
                      title: 'GSTIN / Tax ID Number',
                      subtitle: 'Print tax identification number on receipt',
                      value: cfg.showTaxId,
                      onChanged: (val) => update((c) => c.copyWith(showTaxId: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Receipt Meta
              const Text(
                'Invoice Details & Metadata',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.receipt,
                      title: 'Invoice / Bill Number',
                      subtitle: 'Print "#INV-..." reference code',
                      value: cfg.showInvoiceNumber,
                      onChanged: (val) => update((c) => c.copyWith(showInvoiceNumber: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.access_time,
                      title: 'Date & Time Timestamp',
                      subtitle: 'Print sale creation timestamp',
                      value: cfg.showDateTime,
                      onChanged: (val) => update((c) => c.copyWith(showDateTime: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.person_outline,
                      title: 'Customer Details',
                      subtitle: 'Print customer name when assigned to sale',
                      value: cfg.showCustomerDetails,
                      onChanged: (val) => update((c) => c.copyWith(showCustomerDetails: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.payment,
                      title: 'Payment Mode',
                      subtitle: 'Print Cash, UPI, Card, or Split badge',
                      value: cfg.showPaymentMode,
                      onChanged: (val) => update((c) => c.copyWith(showPaymentMode: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Items & Pricing
              const Text(
                'Items Table & Price Format',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.table_rows_outlined,
                      title: 'Individual Unit Price Column',
                      subtitle: cfg.showItemPrice
                          ? 'Shows ITEM • QTY • PRICE • AMOUNT'
                          : 'Compact mode: ITEM • QTY • AMOUNT',
                      value: cfg.showItemPrice,
                      onChanged: (val) => update((c) => c.copyWith(showItemPrice: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Totals & Payment Breakdown
              const Text(
                'Totals & Breakdown',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.calculate_outlined,
                      title: 'Subtotal & Tax/Discount Breakdown',
                      subtitle: 'Print subtotal, discount, and tax breakdown lines',
                      value: cfg.showSubtotal,
                      onChanged: (val) => update((c) => c.copyWith(showSubtotal: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.monetization_on_outlined,
                      title: 'Grand Total (Highlighted)',
                      subtitle: 'Print bold grand total amount',
                      value: cfg.showGrandTotal,
                      onChanged: (val) => update((c) => c.copyWith(showGrandTotal: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.change_circle_outlined,
                      title: 'Cash Tendered & Change Returned',
                      subtitle: 'Print customer cash handed and change to return',
                      value: cfg.showCashChange,
                      onChanged: (val) => update((c) => c.copyWith(showCashChange: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Kitchen Order Ticket (KOT) & Footer
              const Text(
                'Footer & Kitchen Ticket (KOT)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.favorite_border,
                      title: 'Thank You Message / Footer',
                      subtitle: 'Print receipt footer note at the bottom',
                      value: cfg.showFooter,
                      onChanged: (val) => update((c) => c.copyWith(showFooter: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.restaurant,
                      title: 'Order Ticket / Kitchen KOT Slip',
                      subtitle: 'Print a compact order ticket at bottom of receipt',
                      value: cfg.showOrderTicketKot,
                      onChanged: (val) => update((c) => c.copyWith(showOrderTicketKot: val)),
                    ),
                    const Divider(height: 1),
                    _buildToggleTile(
                      icon: Icons.content_cut,
                      title: 'Auto-Cut Paper After Print',
                      subtitle: 'Send ESC/POS paper cut command when printing ends',
                      value: cfg.cutPaper,
                      onChanged: (val) => update((c) => c.copyWith(cutPaper: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLivePreviewCard(
    BillCustomizerSettings cfg,
    BusinessProfile profile,
    TaxSettings taxSettings,
  ) {
    final currency = profile.currencySymbol.isNotEmpty ? profile.currencySymbol : '₹';
    final hasHeader = (cfg.showBusinessName && profile.restaurantName.isNotEmpty) ||
        (cfg.showTagline && profile.tagline.isNotEmpty) ||
        (cfg.showAddress && profile.address.isNotEmpty) ||
        (cfg.showPhone && profile.phone.isNotEmpty) ||
        (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty);

    final hasMeta = cfg.showInvoiceNumber || cfg.showDateTime || cfg.showCustomerDetails || cfg.showPaymentMode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview Top Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusMedium - 1.5),
                topRight: Radius.circular(AppDimens.radiusMedium - 1.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'LIVE RECEIPT PREVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE SYNC',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),

          // Receipt Simulation Container
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                if (cfg.showBusinessName && profile.restaurantName.isNotEmpty)
                  Text(
                    profile.restaurantName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentNavy, letterSpacing: 0.5),
                  ),
                if (cfg.showTagline && profile.tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(profile.tagline, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                ],
                if (cfg.showAddress && profile.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(profile.address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                ],
                if (cfg.showPhone && profile.phone.isNotEmpty)
                  Text('Phone: ${profile.phone}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                if (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('GSTIN: ${profile.taxRegistrationNumber}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                ],

                if (hasHeader) ...[
                  const SizedBox(height: 8),
                  const Divider(thickness: 0.8),
                  const SizedBox(height: 4),
                ],

                // Metadata
                if (cfg.showInvoiceNumber || cfg.showDateTime)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (cfg.showInvoiceNumber)
                        const Text('Invoice: #INV-1024', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))
                      else
                        const SizedBox(),
                      if (cfg.showDateTime)
                        const Text('11 Sep 2026, 12:30 PM', style: TextStyle(fontSize: 10, color: AppColors.secondaryText))
                      else
                        const SizedBox(),
                    ],
                  ),
                if (cfg.showCustomerDetails) ...[
                  const SizedBox(height: 3),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer:', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                      Text('Walk-in / Priya Sharma', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
                    ],
                  ),
                ],
                if (cfg.showPaymentMode) ...[
                  const SizedBox(height: 3),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Mode:', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                      AppBadge(text: 'CASH', variant: BadgeVariant.primary),
                    ],
                  ),
                ],

                if (hasMeta) ...[
                  const SizedBox(height: 8),
                  const Divider(thickness: 0.8),
                  const SizedBox(height: 4),
                ],

                // Items Table Header
                if (cfg.showItemPrice)
                  const Row(
                    children: [
                      Expanded(flex: 5, child: Text('ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Expanded(flex: 7, child: Text('ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                    ],
                  ),
                const SizedBox(height: 4),
                const Divider(thickness: 0.5),

                // Sample Item 1
                _buildPreviewItemRow('Chicken Biryani', 2, 220.0, 440.0, cfg.showItemPrice, currency),
                // Sample Item 2
                _buildPreviewItemRow('Fresh Lime Soda', 1, 60.0, 60.0, cfg.showItemPrice, currency),

                const SizedBox(height: 6),
                const Divider(thickness: 0.8),
                const SizedBox(height: 4),

                // Totals
                if (cfg.showSubtotal) ...[
                  _buildPreviewSummaryRow('Subtotal', '$currency 500.00'),
                  _buildPreviewSummaryRow('${taxSettings.taxName} (${taxSettings.defaultTaxRate.toStringAsFixed(0)}%)', '$currency 25.00'),
                  _buildPreviewSummaryRow('Round Off', '$currency 0.00'),
                ],

                if (cfg.showGrandTotal) ...[
                  const Divider(thickness: 1.2, color: AppColors.accentNavy),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GRAND TOTAL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accentNavy)),
                        Text('$currency 525.00', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1.2, color: AppColors.accentNavy),
                ],

                if (cfg.showCashChange) ...[
                  const SizedBox(height: 3),
                  _buildPreviewSummaryRow('Cash Tendered', '$currency 600.00'),
                  _buildPreviewSummaryRow('Change Returned', '$currency 75.00', textColor: AppColors.success),
                ],

                if (cfg.showFooter && profile.receiptFooter.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    profile.receiptFooter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                  ),
                ],

                const SizedBox(height: 4),
                const Text(
                  'Powered by Fundamentzz POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.metallicSilver),
                ),

                // KOT Ticket
                if (cfg.showOrderTicketKot) ...[
                  const SizedBox(height: 12),
                  const Divider(thickness: 1.2, color: AppColors.accentNavy),
                  const SizedBox(height: 4),
                  const Text('*** ORDER TICKET ***', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accentNavy, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill No: #INV-1024', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10)),
                      Text('12:30 PM', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(thickness: 0.5),
                  const Row(
                    children: [
                      Expanded(child: Text('Chicken Biryani', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                      Text('2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Expanded(child: Text('Fresh Lime Soda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                      Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(thickness: 1.2, color: AppColors.accentNavy),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPreviewItemRow(
    String name,
    int qty,
    double price,
    double total,
    bool showPrice,
    String currency,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: showPrice ? 5 : 7,
            child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ),
          if (showPrice)
            Expanded(
              flex: 2,
              child: Text(price.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
            ),
          Expanded(
            flex: 3,
            child: Text(total.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Widget _buildPreviewSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.accentNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primaryBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (value ? AppColors.primaryBlue : AppColors.secondaryText).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        child: Icon(icon, size: 18, color: value ? AppColors.primaryBlue : AppColors.secondaryText),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
    );
  }
}
