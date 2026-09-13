import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class BarcodeScannerModal extends StatefulWidget {
  final ValueChanged<String> onBarcodeScanned;

  const BarcodeScannerModal({
    super.key,
    required this.onBarcodeScanned,
  });

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        onBarcodeScanned: (code) => Navigator.pop(ctx, code),
      ),
    );
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> with SingleTickerProviderStateMixin {
  final TextEditingController _barcodeCtrl = TextEditingController();
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  void _submitCode(String code) {
    if (code.trim().isNotEmpty) {
      widget.onBarcodeScanned(code.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Barcode / SKU Scanner',
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
          const SizedBox(height: 12),

          // Scanner Viewfinder Area
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1E42),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(height: 8),
                    const Text(
                      'Position barcode inside the viewfinder',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                // Laser Scan Line Animation
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return Positioned(
                      top: 20 + (_animCtrl.value * 120),
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual Entry
          CustomTextField(
            label: 'Or Enter Barcode / SKU Manually',
            hintText: 'e.g. 8901234501, 8901234506',
            controller: _barcodeCtrl,
            keyboardType: TextInputType.text,
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward, color: AppColors.primaryBlue),
              onPressed: () => _submitCode(_barcodeCtrl.text),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Demo Barcode Chips
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('8901234501 (Paneer 65)', style: TextStyle(fontSize: 11)),
                onPressed: () => _submitCode('8901234501'),
              ),
              ActionChip(
                label: const Text('8901234506 (Biryani)', style: TextStyle(fontSize: 11)),
                onPressed: () => _submitCode('8901234506'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomButton(
            text: 'Confirm Barcode',
            onPressed: () => _submitCode(_barcodeCtrl.text),
          ),
        ],
      ),
    );
  }
}
