import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/app_data_storage_service.dart';
import '../../../data/datasources/sqlite_datasource.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_navigation_shell.dart';
import '../settings/business_profile_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    // 1. Initialize SQLite Database
    await sl<SqliteDataSource>().database;

    // 2. Pre-sync persistent AppData settings into repository cache
    final settingsRepo = sl<SettingsRepository>();
    await settingsRepo.getBusinessProfile();
    await settingsRepo.getTaxSettings();
    await settingsRepo.getPrinterSettings();
    await settingsRepo.getBillCustomizerSettings();

    // 3. Preload in-memory provider state
    if (mounted) {
      final settingsProv = context.read<SettingsProvider>();
      final billingProv = context.read<BillingProvider>();
      final invProv = context.read<InventoryProvider>();
      await settingsProv.init();
      await billingProv.init();
      await invProv.loadProducts();
    }

    // 4. Check if one-time store setup has been completed
    final appDataService = sl<AppDataStorageService>();
    final isSetupDone = await appDataService.isOneTimeSetupCompleted();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      final Widget target = isSetupDone
          ? const MainNavigationShell()
          : const BusinessProfileView(isOneTimeSetup: true);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => target,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Dark black background matching the logo identity
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Fundamentzz Logo Image
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback stylish vector logo if asset fails
                            return Container(
                              color: const Color(0xFF0A1E42),
                              child: const Center(
                                child: Text(
                                  'FZ',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App Title & Tagline
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.6), width: 1.5),
                            bottom: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.6), width: 1.5),
                          ),
                        ),
                        child: const Text(
                          AppStrings.appTagline,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4C8CFF),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Loader
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlueLight),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.appVersion,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
