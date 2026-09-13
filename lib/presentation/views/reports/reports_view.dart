import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/analytics_provider.dart';
import '../dashboard/widgets/metric_card.dart';
import 'category_sales_chart.dart';
import 'date_range_filter_bar.dart';
import 'payment_mode_donut_chart.dart';
import 'profit_loss_report_view.dart';
import 'sales_overview_chart.dart';
import 'top_products_chart.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAnalytics();
    });
  }

  void _pickCustomDateRange() async {
    final analytics = context.read<AnalyticsProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: analytics.startDate, end: analytics.endDate),
    );

    if (range != null) {
      analytics.setCustomRange(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.reportData;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentNavy),
            tooltip: 'Refresh Reports',
            onPressed: () => analytics.loadAnalytics(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Time range filter presets
          DateRangeFilterBar(
            selectedPreset: analytics.selectedPreset,
            onPresetSelected: (preset) => analytics.setPreset(preset),
            onCustomDateTap: _pickCustomDateRange,
          ),

          // Date Range Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.canvas,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat("dd MMM yyyy").format(analytics.startDate)} - ${DateFormat("dd MMM yyyy").format(analytics.endDate)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                ),
                Text(
                  '${data?.totalOrders ?? 0} Transactions',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Analytics Content Body
          Expanded(
            child: analytics.isLoading || data == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final isDesktop = constraints.maxWidth >= 960;

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppDimens.p16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // KPI Cards Grid
                                GridView.count(
                                  crossAxisCount: isWide ? 4 : 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: isWide ? 1.55 : 1.45,
                                  children: [
                                    MetricCard(
                                      title: 'Gross Revenue',
                                      value: CurrencyFormatter.format(data.totalRevenue),
                                      icon: Icons.account_balance,
                                      iconColor: AppColors.primaryBlue,
                                      subtitle: '${data.totalOrders} total bills',
                                    ),
                                    MetricCard(
                                      title: 'Net Profit Estimate',
                                      value: CurrencyFormatter.format(data.netProfit),
                                      icon: Icons.trending_up,
                                      iconColor: data.netProfit >= 0 ? AppColors.success : AppColors.danger,
                                      subtitle: '${data.profitMargin}% net margin',
                                    ),
                                    MetricCard(
                                      title: 'Average Order Value',
                                      value: CurrencyFormatter.format(data.averageOrderValue),
                                      icon: Icons.shopping_bag_outlined,
                                      iconColor: AppColors.info,
                                      subtitle: 'Per transaction',
                                    ),
                                    MetricCard(
                                      title: 'Total Expenses',
                                      value: CurrencyFormatter.format(data.totalExpenses),
                                      icon: Icons.outbox,
                                      iconColor: AppColors.danger,
                                      subtitle: 'Operating costs',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                if (isDesktop) ...[
                                  // Row 1: Sales Trend + Profit & Loss
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: SalesOverviewChart(salesTrend: data.salesTrend)),
                                      const SizedBox(width: 16),
                                      Expanded(child: ProfitLossReportView(data: data)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Row 2: Top Selling + Category Distribution
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: TopProductsChart(topProducts: data.topProducts)),
                                      const SizedBox(width: 16),
                                      Expanded(child: CategorySalesChart(categorySales: data.categorySales)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Row 3: Payment Mode
                                  PaymentModeDonutChart(paymentModes: data.paymentModes),
                                ] else ...[
                                  // 1. Sales Overview Bar/Trend Chart
                                  SalesOverviewChart(salesTrend: data.salesTrend),
                                  const SizedBox(height: 16),

                                  // 2. Profit & Loss Report View
                                  ProfitLossReportView(data: data),
                                  const SizedBox(height: 16),

                                  // 3. Top Selling Products
                                  TopProductsChart(topProducts: data.topProducts),
                                  const SizedBox(height: 16),

                                  // 4. Category-Wise Distribution
                                  CategorySalesChart(categorySales: data.categorySales),
                                  const SizedBox(height: 16),

                                  // 5. Payment Mode Donut Breakdown
                                  PaymentModeDonutChart(paymentModes: data.paymentModes),
                                ],

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
