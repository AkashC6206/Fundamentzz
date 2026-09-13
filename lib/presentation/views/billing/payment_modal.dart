import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/sale.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'receipt_view.dart';

class PaymentModal extends StatefulWidget {
  const PaymentModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PaymentModal(),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  PaymentMode _selectedMode = PaymentMode.cash;
  final TextEditingController _cashTenderedCtrl = TextEditingController();
  final TextEditingController _paymentRefCtrl = TextEditingController();
  double _cashTendered = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final billing = context.read<BillingProvider>();
    _cashTendered = billing.cartTotals.grandTotal;
    _cashTenderedCtrl.text = _cashTendered.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _cashTenderedCtrl.dispose();
    _paymentRefCtrl.dispose();
    super.dispose();
  }

  void _setExactCash(double amount) {
    setState(() {
      _cashTendered = amount;
      _cashTenderedCtrl.text = amount.toStringAsFixed(0);
    });
  }

  void _addCashDenomination(double addAmount) {
    setState(() {
      _cashTendered += addAmount;
      _cashTenderedCtrl.text = _cashTendered.toStringAsFixed(0);
    });
  }

  Future<void> _handlePayment() async {
    final billing = context.read<BillingProvider>();
    final grandTotal = billing.cartTotals.grandTotal;

    if (_selectedMode == PaymentMode.cash && _cashTendered < grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cash tendered (${CurrencyFormatter.format(_cashTendered)}) is less than total amount!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final changeReturned = (_selectedMode == PaymentMode.cash && _cashTendered > grandTotal)
        ? (_cashTendered - grandTotal)
        : 0.0;

    final res = await billing.processCheckout(
      paymentMode: _selectedMode,
      cashTendered: _selectedMode == PaymentMode.cash ? _cashTendered : grandTotal,
      changeReturned: changeReturned,
      paymentRef: _selectedMode == PaymentMode.upi && _paymentRefCtrl.text.trim().isNotEmpty
          ? _paymentRefCtrl.text.trim()
          : null,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (res.isSuccess && res.data != null) {
        Navigator.pop(context); // Close payment modal
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ReceiptView(sale: res.data!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failure?.message ?? 'Payment failed'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final grandTotal = billing.cartTotals.grandTotal;
    final changeAmount = (_cashTendered - grandTotal).clamp(0.0, double.infinity);
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.88).clamp(420.0, 640.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: sheetHeight,
        ),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle & Header
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.metallicSilver,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Total Due Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AMOUNT DUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(grandTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Payment Method Section: Cash, UPI only
              Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      mode: PaymentMode.cash,
                      label: 'Cash',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeTab(
                      mode: PaymentMode.upi,
                      label: 'UPI',
                      icon: Icons.qr_code_2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Payment Details (Cash or UPI)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedMode == PaymentMode.cash) ...[
                        // Cash Tendered Field
                        CustomTextField(
                          label: 'Cash Tendered',
                          controller: _cashTenderedCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.currency_rupee, size: 20, color: AppColors.primaryBlue),
                          onChanged: (val) {
                            setState(() {
                              _cashTendered = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        // Quick Denomination Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Exact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.canvas,
                              onPressed: () => _setExactCash(grandTotal),
                            ),
                            ActionChip(
                              label: const Text('+ ₹100', style: TextStyle(fontSize: 12)),
                              onPressed: () => _addCashDenomination(100),
                            ),
                            ActionChip(
                              label: const Text('+ ₹200', style: TextStyle(fontSize: 12)),
                              onPressed: () => _addCashDenomination(200),
                            ),
                            ActionChip(
                              label: const Text('+ ₹500', style: TextStyle(fontSize: 12)),
                              onPressed: () => _addCashDenomination(500),
                            ),
                            ActionChip(
                              label: const Text('+ ₹2000', style: TextStyle(fontSize: 12)),
                              onPressed: () => _addCashDenomination(2000),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Change Returned Display
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: changeAmount > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.canvas,
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                            border: Border.all(
                              color: changeAmount > 0 ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Change to Return:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentNavy,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(changeAmount),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: changeAmount > 0 ? AppColors.success : AppColors.accentNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // UPI QR Details & Reference
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.qr_code_2,
                                  size: 100,
                                  color: AppColors.accentNavy,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                billing.businessProfile.restaurantName.isNotEmpty
                                    ? billing.businessProfile.restaurantName
                                    : 'Fundamentzz Store',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.account_balance_wallet, size: 14, color: AppColors.primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      billing.businessProfile.upiVpa.isNotEmpty
                                          ? billing.businessProfile.upiVpa
                                          : 'fundamentzz@okhdfcbank',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scan using GPay, PhonePe, Paytm or any UPI App',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'UPI Ref / UTR (Optional)',
                          controller: _paymentRefCtrl,
                          keyboardType: TextInputType.text,
                          prefixIcon: const Icon(Icons.tag, size: 20, color: AppColors.primaryBlue),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Payment Button
              CustomButton(
                text: _selectedMode == PaymentMode.cash
                    ? 'CONFIRM CASH & PRINT RECEIPT'
                    : 'CONFIRM UPI & PRINT RECEIPT',
                icon: Icons.check_circle,
                isLoading: _isProcessing,
                onPressed: _handlePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required PaymentMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
