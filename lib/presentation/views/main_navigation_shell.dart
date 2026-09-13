import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import '../providers/inventory_provider.dart';
import 'billing/new_sale_view.dart';
import 'dashboard/dashboard_view.dart';
import 'inventory/inventory_view.dart';
import 'reports/reports_view.dart';
import 'settings/settings_view.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  final List<Widget> _tabs = const [
    DashboardView(),
    NewSaleView(),
    InventoryView(),
    ReportsView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
      if (index == 1) {
        context.read<BillingProvider>().refreshCatalogue();
      } else if (index == 2) {
        context.read<InventoryProvider>().loadProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 720;

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: switchTab,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surface,
                  selectedIconTheme: const IconThemeData(color: AppColors.primaryBlue),
                  unselectedIconTheme: const IconThemeData(color: AppColors.secondaryText),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Text(
                          'FZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('POS Billing'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventory'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _tabs,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNavy.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => switchTab(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: AppColors.secondaryText,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale_outlined),
                  activeIcon: Icon(Icons.point_of_sale),
                  label: 'POS Billing',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
