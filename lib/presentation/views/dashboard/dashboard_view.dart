import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_history_provider.dart';
import '../billing/held_bills_dialog.dart';
import '../billing/new_sale_view.dart';
import '../inventory/add_edit_product_view.dart';
import '../reports/reports_view.dart';
import '../sales/sale_detail_view.dart';
import '../sales/sales_history_view.dart';
import 'widgets/metric_card.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_sales_ticker.dart';
import 'widgets/sales_trend_mini_chart.dart';

class DashboardView extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardView({super.key, this.onNavigateTab});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    context.read<AnalyticsProvider>().loadAnalytics();
    context.read<SalesHistoryProvider>().loadSales();
    context.read<InventoryProvider>().loadProducts();
    context.read<InventoryProvider>().loadCategories();
    context.read<BillingProvider>().refreshCatalogue();
    context.read<BillingProvider>().loadHeldBills();
  }

  void _startNewSale() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NewSaleView()),
    ).then((_) => _refreshData());
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditProductView()),
    ).then((_) => _refreshData());
  }

  void _openReports() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ReportsView()),
    );
  }

  void _openHeldBills() {
    HeldBillsDialog.show(context);
  }



  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final salesHistory = context.watch<SalesHistoryProvider>();
    final billing = context.watch<BillingProvider>();
    final inventory = context.watch<InventoryProvider>();

    final todaySales = salesHistory.sales.where((s) {
      final now = DateTime.now();
      return s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day &&
          s.status.name == 'completed';
    }).toList();

    final todayRevenue = todaySales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
    final todayOrderCount = todaySales.length;
    final heldBillsCount = billing.heldBills.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: AppColors.primaryGradient,
              ),
              child: const Center(
                child: Text(
                  'FZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentNavy,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  billing.businessProfile.restaurantName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.pause_circle_outline, color: AppColors.accentNavy),
                if (heldBillsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$heldBillsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Held Bills',
            onPressed: _openHeldBills,
          ),

          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentNavy),
            tooltip: 'Refresh Data',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final isDesktop = constraints.maxWidth >= 1000;

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryBlue,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Banner - Quick Billing CTA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quick POS Billing Terminal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Touch-optimized ordering & rapid checkout',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _startNewSale,
                                    icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.primaryBlue),
                                    label: const Text('START NEW SALE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryBlue)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(180, 42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.point_of_sale, size: 48, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Metrics Grid (Today's Sales, Orders, Held Carts, Low Stock)
                      GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.55 : 1.45,
                        children: [
                          MetricCard(
                            title: "Today's Gross Sales",
                            value: CurrencyFormatter.format(todayRevenue),
                            icon: Icons.payments,
                            iconColor: AppColors.success,
                            subtitle: '$todayOrderCount transactions',
                            trendText: '+8.4%',
                            isPositiveTrend: true,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesHistoryView()));
                            },
                          ),
                          MetricCard(
                            title: "Today's Bills",
                            value: '$todayOrderCount',
                            icon: Icons.receipt_long,
                            iconColor: AppColors.primaryBlue,
                            subtitle: 'Avg: ${CurrencyFormatter.format(todayOrderCount > 0 ? todayRevenue / todayOrderCount : 0)}',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesHistoryView()));
                            },
                          ),
                          MetricCard(
                            title: "Held Orders",
                            value: '$heldBillsCount',
                            icon: Icons.pause_circle_filled,
                            iconColor: AppColors.warning,
                            subtitle: 'Pending checkout',
                            onTap: _openHeldBills,
                          ),
                          MetricCard(
                            title: "Total Items",
                            value: '${inventory.products.length}',
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primaryBlue,
                            subtitle: 'In catalogue',
                            onTap: () {
                              widget.onNavigateTab?.call(1); // Jump to Inventory
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Quick Actions Bar
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionButton(
                              label: 'New Sale',
                              icon: Icons.add_shopping_cart,
                              color: AppColors.primaryBlue,
                              onTap: _startNewSale,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: QuickActionButton(
                              label: 'Add Product',
                              icon: Icons.inventory_2,
                              color: AppColors.primaryBlueDark,
                              onTap: _openAddProduct,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: QuickActionButton(
                              label: 'View Reports',
                              icon: Icons.analytics,
                              color: AppColors.info,
                              onTap: _openReports,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: QuickActionButton(
                              label: 'Hold Bills',
                              icon: Icons.pause_circle_outline,
                              color: AppColors.warning,
                              onTap: _openHeldBills,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Charts & Recent Sales Section
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: SalesTrendMiniChart(
                                trendData: analytics.reportData?.salesTrend ?? [],
                                onViewDetails: _openReports,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: RecentSalesTicker(
                                recentSales: salesHistory.sales,
                                onSaleTap: (sale) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => SaleDetailView(saleId: sale.id)),
                                  );
                                },
                                onViewAll: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const SalesHistoryView()),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      else ...[
                        SalesTrendMiniChart(
                          trendData: analytics.reportData?.salesTrend ?? [],
                          onViewDetails: _openReports,
                        ),
                        const SizedBox(height: 18),
                        RecentSalesTicker(
                          recentSales: salesHistory.sales,
                          onSaleTap: (sale) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => SaleDetailView(saleId: sale.id)),
                            );
                          },
                          onViewAll: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SalesHistoryView()),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
