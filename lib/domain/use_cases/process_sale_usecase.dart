import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../entities/customer_ledger_entry.dart';
import '../entities/sale.dart';
import '../entities/stock_adjustment.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

class ProcessSaleUseCase {
  final SaleRepository saleRepository;
  final ProductRepository productRepository;
  final CustomerRepository? customerRepository;

  ProcessSaleUseCase({
    required this.saleRepository,
    required this.productRepository,
    this.customerRepository,
  });

  Future<Result<Sale>> execute(Sale sale) async {
    if (sale.items.isEmpty) {
      return const Result.error(ValidationFailure('Sale items cannot be empty'));
    }

    // 1. Persist Sale
    final createResult = await saleRepository.createSale(sale);
    if (!createResult.isSuccess) {
      return Result.error(createResult.failure);
    }

    // 2. Adjust Product Inventory Stock for each item
    for (final item in sale.items) {
      final prodResult = await productRepository.getProductById(item.productId);
      if (prodResult.isSuccess && prodResult.data != null) {
        final currentProd = prodResult.data!;
        final newStock = (currentProd.stockQuantity - item.quantity);
        final adjustment = StockAdjustment(
          id: const Uuid().v4(),
          productId: item.productId,
          productName: item.productName,
          type: StockAdjustmentType.stockOut,
          quantityChange: -item.quantity,
          newStockQuantity: newStock,
          reason: 'Sale #${sale.invoiceNumber}',
          timestamp: DateTime.now(),
          notes: 'Deducted automatically on sale completion',
        );
        await productRepository.adjustStock(adjustment);
      }
    }

    // 3. If Payment Mode is Credit (Udhaar), record to Customer Ledger
    if (sale.paymentMode == PaymentMode.credit && sale.customerId != null && customerRepository != null) {
      final customerResult = await customerRepository!.getCustomerById(sale.customerId!);
      if (customerResult.isSuccess && customerResult.data != null) {
        final customer = customerResult.data!;
        final newBalance = customer.creditBalance + sale.totalAmount;

        final ledgerEntry = CustomerLedgerEntry(
          id: const Uuid().v4(),
          customerId: customer.id,
          saleId: sale.id,
          type: LedgerEntryType.creditSale,
          amount: sale.totalAmount,
          balanceAfter: newBalance,
          timestamp: sale.createdAt,
          paymentMode: 'Credit (Udhaar)',
          notes: 'Invoice #${sale.invoiceNumber}',
        );

        await customerRepository!.addLedgerEntry(ledgerEntry);
      }
    }

    return Result.success(sale);
  }
}
