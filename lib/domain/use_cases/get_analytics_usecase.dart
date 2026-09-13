import '../../core/utils/result.dart';
import '../entities/product.dart';
import '../entities/sale.dart';
import '../repositories/expense_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

class DailySalesPoint {
  final DateTime date;
  final double salesAmount;
  final int orderCount;

  const DailySalesPoint({
    required this.date,
    required this.salesAmount,
    required this.orderCount,
  });
}

class TopProductStat {
  final String productId;
  final String productName;
  final String categoryName;
  final double quantitySold;
  final double revenue;

  const TopProductStat({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
  });
}

class CategorySalesStat {
  final String categoryName;
  final double revenue;
  final double percentage;

  const CategorySalesStat({
    required this.categoryName,
    required this.revenue,
    required this.percentage,
  });
}

class PaymentModeStat {
  final PaymentMode mode;
  final String name;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  const PaymentModeStat({
    required this.mode,
    required this.name,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });
}

class AnalyticsReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double totalDiscount;
  final double totalTax;
  final double totalCostOfGoods;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final double profitMargin; // Percentage

  final List<DailySalesPoint> salesTrend;
  final List<TopProductStat> topProducts;
  final List<CategorySalesStat> categorySales;
  final List<PaymentModeStat> paymentModes;
  final List<Product> lowStockProducts;

  const AnalyticsReportData({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalCostOfGoods,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.salesTrend,
    required this.topProducts,
    required this.categorySales,
    required this.paymentModes,
    required this.lowStockProducts,
  });
}

class GetAnalyticsUseCase {
  final SaleRepository saleRepository;
  final ExpenseRepository expenseRepository;
  final ProductRepository productRepository;

  GetAnalyticsUseCase({
    required this.saleRepository,
    required this.expenseRepository,
    required this.productRepository,
  });

  Future<Result<AnalyticsReportData>> execute({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 1. Fetch Sales in Date Range
    final salesRes = await saleRepository.getSales(startDate: startDate, endDate: endDate);
    if (!salesRes.isSuccess) {
      return Result.error(salesRes.failure);
    }
    final sales = salesRes.data ?? [];

    // 2. Fetch Expenses in Date Range
    final expRes = await expenseRepository.getExpenses(startDate: startDate, endDate: endDate);
    final expenses = expRes.data ?? [];

    // 3. Fetch Low Stock Products
    final lowStockRes = await productRepository.getLowStockProducts();
    final lowStockProducts = lowStockRes.data ?? [];

    // 4. Compute Aggregate Totals
    double totalRevenue = 0.0;
    int totalOrders = sales.where((s) => s.status == SaleStatus.completed).length;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    double totalCostOfGoods = 0.0;

    final Map<String, _ProductAccumulator> productMap = {};
    final Map<String, double> categoryMap = {};
    final Map<PaymentMode, _PaymentAccumulator> paymentMap = {
      PaymentMode.cash: _PaymentAccumulator('Cash'),
      PaymentMode.card: _PaymentAccumulator('Card'),
      PaymentMode.upi: _PaymentAccumulator('UPI'),
      PaymentMode.credit: _PaymentAccumulator('Credit / Udhaar'),
      PaymentMode.split: _PaymentAccumulator('Split'),
    };

    // Build day map for trend
    final Map<String, _DayAccumulator> dayMap = {};
    final totalDays = endDate.difference(startDate).inDays.clamp(1, 90);
    for (int i = 0; i <= totalDays; i++) {
      final d = startDate.add(Duration(days: i));
      if (d.isAfter(endDate)) break;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dayMap[key] = _DayAccumulator(d);
    }

    for (final sale in sales) {
      if (sale.status != SaleStatus.completed) continue;

      totalRevenue += sale.totalAmount;
      totalDiscount += sale.discountAmount;
      totalTax += sale.taxAmount;
      totalCostOfGoods += sale.costTotal;

      // Group by payment mode
      final payAcc = paymentMap[sale.paymentMode];
      if (payAcc != null) {
        payAcc.amount += sale.totalAmount;
        payAcc.count += 1;
      }

      // Group by day
      final dayKey = '${sale.createdAt.year}-${sale.createdAt.month.toString().padLeft(2, '0')}-${sale.createdAt.day.toString().padLeft(2, '0')}';
      if (dayMap.containsKey(dayKey)) {
        dayMap[dayKey]!.amount += sale.totalAmount;
        dayMap[dayKey]!.count += 1;
      } else {
        dayMap[dayKey] = _DayAccumulator(sale.createdAt)
          ..amount = sale.totalAmount
          ..count = 1;
      }

      // Group items
      for (final item in sale.items) {
        if (!productMap.containsKey(item.productId)) {
          productMap[item.productId] = _ProductAccumulator(
            id: item.productId,
            name: item.productName,
            category: item.categoryName,
          );
        }
        productMap[item.productId]!.quantity += item.quantity;
        productMap[item.productId]!.revenue += item.totalAmount;

        categoryMap[item.categoryName] = (categoryMap[item.categoryName] ?? 0.0) + item.totalAmount;
      }
    }

    double totalExpenses = expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
    double grossProfit = totalRevenue - totalCostOfGoods;
    double netProfit = grossProfit - totalExpenses;
    double averageOrderValue = totalOrders > 0 ? (totalRevenue / totalOrders) : 0.0;
    double profitMargin = totalRevenue > 0 ? ((netProfit / totalRevenue) * 100) : 0.0;

    // Build trend list
    final salesTrend = dayMap.values.map((v) => DailySalesPoint(
      date: v.date,
      salesAmount: v.amount,
      orderCount: v.count,
    )).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Build top products
    final topProductsList = productMap.values.map((p) => TopProductStat(
      productId: p.id,
      productName: p.name,
      categoryName: p.category,
      quantitySold: p.quantity,
      revenue: p.revenue,
    )).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Build category stats
    final categoryStatsList = categoryMap.entries.map((e) {
      final pct = totalRevenue > 0 ? (e.value / totalRevenue) * 100 : 0.0;
      return CategorySalesStat(
        categoryName: e.key.isNotEmpty ? e.key : 'General',
        revenue: e.value,
        percentage: double.parse(pct.toStringAsFixed(1)),
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Build payment stats
    final paymentStatsList = paymentMap.entries.map((e) {
      final pct = totalRevenue > 0 ? (e.value.amount / totalRevenue) * 100 : 0.0;
      return PaymentModeStat(
        mode: e.key,
        name: e.value.name,
        totalAmount: e.value.amount,
        transactionCount: e.value.count,
        percentage: double.parse(pct.toStringAsFixed(1)),
      );
    }).toList();

    return Result.success(AnalyticsReportData(
      startDate: startDate,
      endDate: endDate,
      totalRevenue: double.parse(totalRevenue.toStringAsFixed(2)),
      totalOrders: totalOrders,
      averageOrderValue: double.parse(averageOrderValue.toStringAsFixed(2)),
      totalDiscount: double.parse(totalDiscount.toStringAsFixed(2)),
      totalTax: double.parse(totalTax.toStringAsFixed(2)),
      totalCostOfGoods: double.parse(totalCostOfGoods.toStringAsFixed(2)),
      totalExpenses: double.parse(totalExpenses.toStringAsFixed(2)),
      grossProfit: double.parse(grossProfit.toStringAsFixed(2)),
      netProfit: double.parse(netProfit.toStringAsFixed(2)),
      profitMargin: double.parse(profitMargin.toStringAsFixed(1)),
      salesTrend: salesTrend,
      topProducts: topProductsList,
      categorySales: categoryStatsList,
      paymentModes: paymentStatsList,
      lowStockProducts: lowStockProducts,
    ));
  }
}

class _DayAccumulator {
  final DateTime date;
  double amount = 0.0;
  int count = 0;
  _DayAccumulator(this.date);
}

class _ProductAccumulator {
  final String id;
  final String name;
  final String category;
  double quantity = 0.0;
  double revenue = 0.0;
  _ProductAccumulator({required this.id, required this.name, required this.category});
}

class _PaymentAccumulator {
  final String name;
  double amount = 0.0;
  int count = 0;
  _PaymentAccumulator(this.name);
}
