import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String symbol = '₹'}) {
    if (amount >= 10000000) {
      return '$symbol ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '$symbol ${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(1)} k';
    }
    return format(amount, symbol: symbol);
  }
}
