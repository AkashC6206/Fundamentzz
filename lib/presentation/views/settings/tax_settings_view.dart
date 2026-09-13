import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../domain/entities/tax_settings.dart';
import '../../providers/billing_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TaxSettingsView extends StatefulWidget {
  const TaxSettingsView({super.key});

  @override
  State<TaxSettingsView> createState() => _TaxSettingsViewState();
}

class _TaxSettingsViewState extends State<TaxSettingsView> {
  final _formKey = GlobalKey<FormState>();

  late bool _isTaxEnabled;
  late bool _isTaxInclusive;
  late TextEditingController _taxNameCtrl;
  late TextEditingController _defaultTaxRateCtrl;
  late bool _isServiceChargeEnabled;
  late TextEditingController _serviceChargeRateCtrl;
  late bool _isRoundOffEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().taxSettings;
    _isTaxEnabled = settings.isTaxEnabled;
    _isTaxInclusive = settings.isTaxInclusive;
    _taxNameCtrl = TextEditingController(text: settings.taxName);
    _defaultTaxRateCtrl = TextEditingController(text: settings.defaultTaxRate.toString());
    _isServiceChargeEnabled = settings.isServiceChargeEnabled;
    _serviceChargeRateCtrl = TextEditingController(text: settings.serviceChargeRate.toString());
    _isRoundOffEnabled = settings.isRoundOffEnabled;
  }

  @override
  void dispose() {
    _taxNameCtrl.dispose();
    _defaultTaxRateCtrl.dispose();
    _serviceChargeRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = TaxSettings(
      isTaxEnabled: _isTaxEnabled,
      isTaxInclusive: _isTaxInclusive,
      taxName: _taxNameCtrl.text.trim().isNotEmpty ? _taxNameCtrl.text.trim() : 'GST',
      defaultTaxRate: double.tryParse(_defaultTaxRateCtrl.text) ?? 5.0,
      isServiceChargeEnabled: _isServiceChargeEnabled,
      serviceChargeRate: double.tryParse(_serviceChargeRateCtrl.text) ?? 0.0,
      isRoundOffEnabled: _isRoundOffEnabled,
    );

    final res = await context.read<SettingsProvider>().saveTaxSettings(updated);
    if (mounted) {
      await context.read<BillingProvider>().loadSettings();
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax settings updated!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.failure?.message ?? 'Failed to update tax rules'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Tax & Charges Configuration')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            children: [
              // Tax Rules Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tax Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Tax on Billing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Calculate tax automatically for eligible menu items', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      value: _isTaxEnabled,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _isTaxEnabled = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prices are Tax-Inclusive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Menu price includes tax rather than adding on top', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      value: _isTaxInclusive,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _isTaxInclusive = val),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Tax Name / Label',
                            hintText: 'e.g. GST, VAT',
                            controller: _taxNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Default Rate (%)',
                            hintText: 'e.g. 5.0',
                            controller: _defaultTaxRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Service Charge & Rounding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Charge & Round Off', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Service Charge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Add service charge percentage to dine-in orders', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      value: _isServiceChargeEnabled,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _isServiceChargeEnabled = val),
                    ),
                    if (_isServiceChargeEnabled) ...[
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Service Charge Percentage (%)',
                        hintText: 'e.g. 2.5',
                        controller: _serviceChargeRateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Grand Total Round-Off', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Rounds final payable bill amount to the nearest whole integer', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      value: _isRoundOffEnabled,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _isRoundOffEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: 'SAVE TAX CONFIGURATION',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveSettings,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
