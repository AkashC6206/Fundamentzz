import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/custom_card.dart';

class HelpFaqView extends StatelessWidget {
  const HelpFaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('How to Use & FAQs')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.p16),
        children: [
          _buildFaqItem(
            'How do I create and complete a new sale?',
            '1. Tap "⚡ New Sale" from Dashboard or POS tab.\n2. Tap items in the menu grid to add them to your cart.\n3. Adjust quantities or add cooking notes as required.\n4. Tap "CHARGE / PAY", select your payment mode (Cash, UPI QR, Card, or Credit), and confirm to generate the receipt.',
          ),
          _buildFaqItem(
            'How do Hold Bills work in a busy restaurant?',
            'If a table places an order and will pay later, tap "Hold Bill" in the cart sheet, enter their Table number or token, and save it. You can resume and checkout that table at any time from the "Held Orders" tab.',
          ),
          _buildFaqItem(
            'How do I track customer credit (Udhaar) and receive settlements?',
            '1. Attach a customer to the sale using the customer selector in the billing screen.\n2. Choose "Credit (Udhaar)" as the payment mode.\n3. The balance will automatically log to the customer’s ledger. When the customer pays later, open "Customers", select their profile, and tap "Record Payment" to settle the outstanding balance.',
          ),
          _buildFaqItem(
            'How do I connect a Bluetooth thermal printer?',
            'Go to Settings -> Bluetooth Thermal Printer. Scan for nearby ESC/POS devices (supports 58mm & 80mm rolls), tap "Connect", and run a "Test Print Slip" to verify your printer.',
          ),
          _buildFaqItem(
            'Can I back up my restaurant data?',
            'Yes! Because Fundamentzz works 100% offline with zero cloud dependency, you can export a full JSON database snapshot at any time under Settings -> Backup & Data Management -> Export & Share Backup.',
          ),
          _buildFaqItem(
            'How is Net Profit calculated in the Reports tab?',
            'Net Profit is calculated automatically using:\nNet Profit = Gross Sales Revenue - Cost of Goods Sold (COGS) - Operating Expenses. Make sure to input cost prices for your products and log operating expenses for precise reporting.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
