import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/app_data_storage_service.dart';
import '../../../domain/entities/business_profile.dart';
import '../../providers/billing_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_navigation_shell.dart';

class BusinessProfileView extends StatefulWidget {
  final bool isOneTimeSetup;

  const BusinessProfileView({super.key, this.isOneTimeSetup = false});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _upiCtrl;
  late TextEditingController _footerCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SettingsProvider>().businessProfile;
    _nameCtrl = TextEditingController(text: profile.restaurantName);
    _taglineCtrl = TextEditingController(text: profile.tagline);
    _addressCtrl = TextEditingController(text: profile.address);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _emailCtrl = TextEditingController(text: profile.email);
    _gstinCtrl = TextEditingController(text: profile.taxRegistrationNumber);
    _currencyCtrl = TextEditingController(text: profile.currencySymbol);
    _upiCtrl = TextEditingController(text: profile.upiVpa);
    _footerCtrl = TextEditingController(text: profile.receiptFooter);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _currencyCtrl.dispose();
    _upiCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = BusinessProfile(
      restaurantName: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      taxRegistrationNumber: _gstinCtrl.text.trim(),
      currencySymbol: _currencyCtrl.text.trim().isNotEmpty ? _currencyCtrl.text.trim() : '₹',
      upiVpa: _upiCtrl.text.trim(),
      receiptFooter: _footerCtrl.text.trim(),
    );

    final res = await context.read<SettingsProvider>().saveProfile(updated);

    if (mounted) {
      await context.read<BillingProvider>().loadSettings();
      await sl<AppDataStorageService>().markOneTimeSetupCompleted(true);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile permanently saved in AppData!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (widget.isOneTimeSetup) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationShell()),
          );
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failure?.message ?? 'Failed to update profile'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _continueWithDefault() async {
    await sl<AppDataStorageService>().markOneTimeSetupCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.isOneTimeSetup ? 'One-Time Store Setup' : 'Business Profile & Store Info'),
        automaticallyImplyLeading: !widget.isOneTimeSetup,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            children: [
              if (widget.isOneTimeSetup)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'One-Time Store Setup',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Welcome to Fundamentzz POS! Please enter your store details once. Your profile and settings will be permanently saved in AppData and will appear on all your receipts.',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),

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
                    const Text('Establishment Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Restaurant / Business Name *',
                      hintText: 'e.g. Fundamentzz Bistro',
                      controller: _nameCtrl,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Tagline / Slogan',
                      hintText: 'e.g. Innovation Starts with Fundamentals',
                      controller: _taglineCtrl,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Address (for receipts)',
                      hintText: 'e.g. 104 1st Cross, Indiranagar, Bangalore',
                      controller: _addressCtrl,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                    const Text('Contact & Tax Identifiers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Contact Phone',
                            hintText: 'e.g. +91 9876543210',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Currency Symbol',
                            hintText: 'e.g. ₹, \$, €',
                            controller: _currencyCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'GSTIN / Tax ID',
                      hintText: 'e.g. 29ABCDE1234F1Z5',
                      controller: _gstinCtrl,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'UPI ID (For Quick QR generation)',
                      hintText: 'e.g. fundamentzz@okhdfcbank',
                      controller: _upiCtrl,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Receipt Footer Thank You Message',
                      hintText: 'e.g. Thank you for dining with us! Please visit again.',
                      controller: _footerCtrl,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: widget.isOneTimeSetup ? 'COMPLETE SETUP & START BILLING' : 'SAVE BUSINESS PROFILE',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveProfile,
              ),

              if (widget.isOneTimeSetup) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _continueWithDefault,
                    child: const Text(
                      'Continue with Default Profile for now',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
