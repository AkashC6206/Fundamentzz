import '../../core/utils/result.dart';
import '../entities/held_bill.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Result<String>> createSale(Sale sale);
  Future<Result<Sale>> getSaleById(String id);
  Future<Result<List<Sale>>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    PaymentMode? paymentMode,
  });
  Future<Result<void>> refundSale(String id, String reason);
  Future<Result<String>> getNextInvoiceNumber();

  // Held Bills
  Future<Result<void>> saveHeldBill(HeldBill heldBill);
  Future<Result<List<HeldBill>>> getHeldBills();
  Future<Result<void>> deleteHeldBill(String id);
}
