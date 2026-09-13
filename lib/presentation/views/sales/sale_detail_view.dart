import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/services/receipt_generator_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/repositories/sale_repository.dart';
import '../../providers/billing_provider.dart';
import '../../providers/sales_history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text_field.dart';

class SaleDetailView extends StatefulWidget {
  final String saleId;

  const SaleDetailView({super.key, required this.saleId});

  @override
  State<SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<SaleDetailView> {
  Sale? _sale;
  bool _isLoading = true;
  bool _isThermalPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadSaleDetail();
  }

  Future<void> _loadSaleDetail() async {
    setState(() => _isLoading = true);
    final saleRepo = context.read<SaleRepository>();
    final res = await saleRepo.getSaleById(widget.saleId);
    if (mounted) {
      setState(() {
        _sale = res.data;
        _isLoading = false;
      });
    }
  }

  Future<void> _reprintReceipt() async {
    if (_sale == null) return;
    final billing = context.read<BillingProvider>();
    final settings = context.read<SettingsProvider>();
    final service = ReceiptGeneratorService();
    await service.printReceipt(
      sale: _sale!,
      profile: billing.businessProfile,
      taxSettings: billing.taxSettings,
      customizerSettings: settings.billCustomizerSettings,
    );
  }

  Future<void> _shareReceipt() async {
    if (_sale == null) return;
    final billing = context.read<BillingProvider>();
    final settings = context.read<SettingsProvider>();
    final service = ReceiptGeneratorService();
    await service.shareReceipt(
      sale: _sale!,
      profile: billing.businessProfile,
      taxSettings: billing.taxSettings,
      customizerSettings: settings.billCustomizerSettings,
    );
  }

  Future<void> _printThermalBluetooth() async {
    if (_sale == null) return;
    setState(() => _isThermalPrinting = true);
    final settings = context.read<SettingsProvider>();
    final success = await settings.printSaleReceipt(_sale!);
    setState(() => _isThermalPrinting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thermal receipt reprinted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Bluetooth printer connected or print failed.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  void _showRefundDialog() {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Refund / Cancellation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to refund Invoice #${_sale?.invoiceNumber} (${CurrencyFormatter.format(_sale?.totalAmount ?? 0)})?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Reason for Refund',
              hintText: 'e.g. Customer cancelled, quality issue',
              controller: reasonCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final salesProv = context.read<SalesHistoryProvider>();
              await salesProv.refundSale(widget.saleId, reasonCtrl.text.trim());
              await _loadSaleDetail();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction refunded successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Confirm Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sale == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final sale = _sale!;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Invoice #${sale.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryBlue),
            tooltip: 'Share PDF',
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primaryBlue),
            tooltip: 'Reprint Receipt',
            onPressed: _reprintReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          children: [
            // Status Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (sale.status == SaleStatus.refunded ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sale.status == SaleStatus.refunded ? Icons.replay : Icons.receipt_long,
                      color: sale.status == SaleStatus.refunded ? AppColors.danger : AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Invoice #${sale.invoiceNumber}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
                            ),
                            const SizedBox(width: 8),
                            AppBadge(
                              text: sale.status == SaleStatus.refunded ? 'REFUNDED' : 'PAID',
                              variant: sale.status == SaleStatus.refunded ? BadgeVariant.danger : BadgeVariant.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatDateTime(sale.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(sale.totalAmount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Meta Details
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetaRow('Payment Method', sale.paymentMode.name.toUpperCase()),
                  if (sale.paymentReference != null && sale.paymentReference!.isNotEmpty)
                    _buildMetaRow('Payment Reference / UTR', sale.paymentReference!),
                  if (sale.note.isNotEmpty)
                    _buildMetaRow('Order Note / Reference', sale.note),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Line items card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Purchased Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sale.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = sale.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                if (item.note.isNotEmpty)
                                  Text('Note: ${item.note}', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          Text('${item.quantity.toInt()} x ${CurrencyFormatter.format(item.unitPrice)}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                          const SizedBox(width: 16),
                          Text(CurrencyFormatter.format(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow('Subtotal', CurrencyFormatter.format(sale.subtotal)),
                  if (sale.discountAmount > 0)
                    _buildSummaryRow('Discount', '- ${CurrencyFormatter.format(sale.discountAmount)}', textColor: AppColors.success),
                  if (sale.taxAmount > 0)
                    _buildSummaryRow('Tax', CurrencyFormatter.format(sale.taxAmount)),
                  if (sale.serviceCharge > 0)
                    _buildSummaryRow('Service Charge', CurrencyFormatter.format(sale.serviceCharge)),
                  if (sale.roundOff != 0)
                    _buildSummaryRow('Round Off', CurrencyFormatter.format(sale.roundOff)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(CurrencyFormatter.format(sale.totalAmount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions
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
                    text: 'Reprint (PDF)',
                    icon: Icons.picture_as_pdf,
                    variant: ButtonVariant.outline,
                    onPressed: _reprintReceipt,
                  ),
                ),
                if (sale.status == SaleStatus.completed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Refund Sale',
                      icon: Icons.replay,
                      variant: ButtonVariant.danger,
                      onPressed: _showRefundDialog,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? AppColors.accentNavy)),
        ],
      ),
    );
  }
}
