import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/sale.dart';
import '../../providers/sales_history_provider.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/custom_card.dart';
import 'sale_detail_view.dart';

class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({super.key});

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesHistoryProvider>().loadSales();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pickDateRange() async {
    final provider = context.read<SalesHistoryProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: provider.startDate != null && provider.endDate != null
          ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
          : null,
    );

    if (range != null) {
      provider.setDateRange(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesProv = context.watch<SalesHistoryProvider>();
    final sales = salesProv.sales;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Sales & Invoices History'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: salesProv.startDate != null ? AppColors.primaryBlue : AppColors.accentNavy,
            ),
            tooltip: 'Filter Date Range',
            onPressed: _pickDateRange,
          ),
          if (salesProv.startDate != null || salesProv.filterPaymentMode != null)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.danger),
              tooltip: 'Clear Filters',
              onPressed: () {
                salesProv.setDateRange(null, null);
                salesProv.setFilterPaymentMode(null);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchCtrl,
                  hintText: 'Search by Invoice #, Customer, or Phone...',
                  onChanged: (val) => salesProv.search(val),
                ),
                const SizedBox(height: 8),

                // Payment Mode Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPaymentFilterChip(salesProv, null, 'All Payments'),
                      _buildPaymentFilterChip(salesProv, PaymentMode.cash, 'Cash'),
                      _buildPaymentFilterChip(salesProv, PaymentMode.upi, 'UPI'),
                      _buildPaymentFilterChip(salesProv, PaymentMode.card, 'Card'),
                      _buildPaymentFilterChip(salesProv, PaymentMode.credit, 'Credit (Udhaar)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Overview banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.canvas,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${sales.length} transactions found',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(salesProv.totalFilteredSales)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of Sales
          Expanded(
            child: salesProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sales.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Invoices Found',
                        message: 'Try adjusting your search query or date range filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: sales.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return CustomCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => SaleDetailView(saleId: sale.id)),
                              );
                            },
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '#${sale.invoiceNumber}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.accentNavy,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AppBadge(
                                          text: sale.paymentMode.name.toUpperCase(),
                                          variant: sale.paymentMode == PaymentMode.credit ? BadgeVariant.warning : BadgeVariant.primary,
                                        ),
                                        if (sale.status == SaleStatus.refunded) ...[
                                          const SizedBox(width: 6),
                                          const AppBadge(text: 'REFUNDED', variant: BadgeVariant.danger),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      CurrencyFormatter.format(sale.totalAmount),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: sale.status == SaleStatus.refunded ? AppColors.secondaryText : AppColors.accentNavy,
                                        decoration: sale.status == SaleStatus.refunded ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${sale.customerName ?? "Walk-in Guest"} • ${sale.totalItemCount} items',
                                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatDateTime(sale.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFilterChip(SalesHistoryProvider provider, PaymentMode? mode, String label) {
    final isSelected = provider.filterPaymentMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        onSelected: (_) => provider.setFilterPaymentMode(mode),
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
