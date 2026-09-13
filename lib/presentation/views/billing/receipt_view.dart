import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/services/receipt_generator_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/sale.dart';
import '../../providers/billing_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../main_navigation_shell.dart';
import '../settings/printer_setup_view.dart';

class ReceiptView extends StatefulWidget {
  final Sale sale;

  const ReceiptView({super.key, required this.sale});

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  bool _isSharing = false;
  bool _isPrinting = false;
  bool _isThermalPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (settings.autoPrintOnSale && settings.selectedPrinter != null) {
        _printThermalBluetooth();
      }
    });
  }

  Future<void> _printThermalBluetooth() async {
    setState(() => _isThermalPrinting = true);
    final settings = context.read<SettingsProvider>();
    final success = await settings.printSaleReceipt(widget.sale);
    setState(() => _isThermalPrinting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thermal receipt printed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No Bluetooth printer connected.'),
            backgroundColor: AppColors.warning,
            action: SnackBarAction(
              label: 'Setup',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSetupView()));
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt() async {
    setState(() => _isSharing = true);
    final billing = context.read<BillingProvider>();
    final settings = context.read<SettingsProvider>();
    final receiptService = ReceiptGeneratorService();
    await receiptService.shareReceipt(
      sale: widget.sale,
      profile: billing.businessProfile,
      taxSettings: billing.taxSettings,
      customizerSettings: settings.billCustomizerSettings,
    );
    setState(() => _isSharing = false);
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    final billing = context.read<BillingProvider>();
    final settings = context.read<SettingsProvider>();
    final receiptService = ReceiptGeneratorService();
    await receiptService.printReceipt(
      sale: widget.sale,
      profile: billing.businessProfile,
      taxSettings: billing.taxSettings,
      customizerSettings: settings.billCustomizerSettings,
    );
    setState(() => _isPrinting = false);
  }

  void _handleBackToPos(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationShell(initialIndex: 1)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final settings = context.watch<SettingsProvider>();
    final cfg = settings.billCustomizerSettings;
    final profile = billing.businessProfile;
    final taxSettings = billing.taxSettings;
    final sale = widget.sale;

    final hasHeader = (cfg.showBusinessName && profile.restaurantName.isNotEmpty) ||
        (cfg.showTagline && profile.tagline.isNotEmpty) ||
        (cfg.showAddress && profile.address.isNotEmpty) ||
        (cfg.showPhone && profile.phone.isNotEmpty) ||
        (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty);

    final hasMeta = cfg.showInvoiceNumber ||
        cfg.showDateTime ||
        (cfg.showCustomerDetails && sale.customerName != null && sale.customerName!.isNotEmpty) ||
        cfg.showPaymentMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToPos(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to POS Billing',
            onPressed: () => _handleBackToPos(context),
          ),
          title: const Text('Invoice & Receipt'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primaryBlue),
              tooltip: 'Share Receipt PDF',
              onPressed: _isSharing ? null : _shareReceipt,
            ),
            IconButton(
              icon: const Icon(Icons.print, color: AppColors.primaryBlue),
              tooltip: 'Print Receipt',
              onPressed: _isPrinting ? null : _printReceipt,
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          children: [
            // Success indicator header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Successful!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'Invoice #${sale.invoiceNumber} recorded in local database',
                          style: const TextStyle(fontSize: 11, color: AppColors.accentNavy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thermal Slip Style Container
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Store & Header Information
                  if (cfg.showBusinessName && profile.restaurantName.isNotEmpty)
                    Text(
                      profile.restaurantName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (cfg.showTagline && profile.tagline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                  if (cfg.showAddress && profile.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                  if (cfg.showPhone && profile.phone.isNotEmpty)
                    Text(
                      'Phone: ${profile.phone}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  if (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'GSTIN / Tax ID: ${profile.taxRegistrationNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],

                  if (hasHeader) ...[
                    const SizedBox(height: 12),
                    const Divider(thickness: 1),
                    const SizedBox(height: 8),
                  ],

                  // 2. Invoice Details & Metadata
                  if (cfg.showInvoiceNumber || cfg.showDateTime)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (cfg.showInvoiceNumber)
                          Text(
                            'Invoice: #${sale.invoiceNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          )
                        else
                          const SizedBox(),
                        if (cfg.showDateTime)
                          Text(
                            DateFormatter.formatDateTime(sale.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          )
                        else
                          const SizedBox(),
                      ],
                    ),
                  if (cfg.showCustomerDetails && sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer:', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                        Text(
                          sale.customerName!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (sale.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Reference:', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                        Text(
                          sale.note,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (cfg.showPaymentMode) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode:', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                        AppBadge(
                          text: sale.paymentMode.name.toUpperCase(),
                          variant: BadgeVariant.primary,
                        ),
                      ],
                    ),
                  ],

                  if (hasMeta) ...[
                    const SizedBox(height: 12),
                    const Divider(thickness: 1),
                    const SizedBox(height: 8),
                  ],

                  // 3. Items Table Header
                  if (cfg.showItemPrice)
                    Row(
                      children: const [
                        Expanded(flex: 5, child: Text('ITEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                    )
                  else
                    Row(
                      children: const [
                        Expanded(flex: 7, child: Text('ITEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  const SizedBox(height: 6),
                  const Divider(thickness: 0.5),

                  // Item Rows
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: cfg.showItemPrice ? 5 : 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                if (item.note.isNotEmpty)
                                  Text('(${item.note})', style: const TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${item.quantity.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                          ),
                          if (cfg.showItemPrice)
                            Expanded(
                              flex: 2,
                              child: Text(CurrencyFormatter.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                            ),
                          Expanded(
                            flex: 3,
                            child: Text(CurrencyFormatter.format(item.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  // 4. Totals summary
                  if (cfg.showSubtotal) ...[
                    _buildSummaryRow('Subtotal', CurrencyFormatter.format(sale.subtotal)),
                    if (sale.discountAmount > 0)
                      _buildSummaryRow('Discount', '- ${CurrencyFormatter.format(sale.discountAmount)}', textColor: AppColors.success),
                    if (sale.taxAmount > 0)
                      _buildSummaryRow('${taxSettings.taxName} (Tax)', CurrencyFormatter.format(sale.taxAmount)),
                    if (sale.serviceCharge > 0)
                      _buildSummaryRow('Service Charge', CurrencyFormatter.format(sale.serviceCharge)),
                    if (sale.roundOff != 0)
                      _buildSummaryRow('Round Off', CurrencyFormatter.format(sale.roundOff)),
                  ],

                  if (cfg.showGrandTotal) ...[
                    const Divider(thickness: 1.5, color: AppColors.accentNavy),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GRAND TOTAL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accentNavy),
                          ),
                          Text(
                            CurrencyFormatter.format(sale.totalAmount),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1.5, color: AppColors.accentNavy),
                  ],

                  if (cfg.showCashChange && sale.paymentMode == PaymentMode.cash && sale.cashTendered > 0) ...[
                    const SizedBox(height: 4),
                    _buildSummaryRow('Cash Tendered', CurrencyFormatter.format(sale.cashTendered)),
                    _buildSummaryRow('Change Returned', CurrencyFormatter.format(sale.changeReturned), textColor: AppColors.success),
                  ],

                  if (cfg.showFooter && profile.receiptFooter.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      profile.receiptFooter,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Powered by Fundamentzz POS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.metallicSilver),
                  ),

                  // 5. Kitchen Order Ticket (KOT)
                  if (cfg.showOrderTicketKot) ...[
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.5, color: AppColors.accentNavy),
                    const SizedBox(height: 6),
                    const Text(
                      '*** ORDER TICKET ***',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accentNavy, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bill No: #${sale.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(DateFormatter.formatTime(sale.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                    if (sale.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Ref: ${sale.note}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.secondaryText)),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Divider(thickness: 0.8),
                    ...sale.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                              Text('${item.quantity.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 6),
                    const Divider(thickness: 1.5, color: AppColors.accentNavy),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            CustomButton(
              text: 'Print Slip (Thermal Bluetooth)',
              icon: Icons.print,
              isLoading: _isThermalPrinting,
              onPressed: _printThermalBluetooth,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Share PDF',
                    icon: Icons.share,
                    variant: ButtonVariant.outline,
                    isLoading: _isSharing,
                    onPressed: _shareReceipt,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: 'System Print (PDF)',
                    icon: Icons.picture_as_pdf,
                    variant: ButtonVariant.outline,
                    isLoading: _isPrinting,
                    onPressed: _printReceipt,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Next Sale (New)',
                    icon: Icons.add_shopping_cart,
                    variant: ButtonVariant.secondary,
                    onPressed: () => _handleBackToPos(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    text: 'Dashboard',
                    icon: Icons.dashboard,
                    variant: ButtonVariant.ghost,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  static Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.accentNavy,
            ),
          ),
        ],
      ),
    );
  }
}
