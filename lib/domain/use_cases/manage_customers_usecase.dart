import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../entities/customer.dart';
import '../entities/customer_ledger_entry.dart';
import '../repositories/customer_repository.dart';

class ManageCustomersUseCase {
  final CustomerRepository _repository;

  ManageCustomersUseCase(this._repository);

  Future<Result<List<Customer>>> getCustomers({String? searchQuery}) {
    return _repository.getCustomers(searchQuery: searchQuery);
  }

  Future<Result<Customer>> getCustomerById(String id) {
    return _repository.getCustomerById(id);
  }

  Future<Result<void>> saveCustomer(Customer customer) {
    if (customer.name.trim().isEmpty) {
      return Future.value(const Result.error(ValidationFailure('Customer name cannot be empty')));
    }
    return _repository.saveCustomer(customer);
  }

  Future<Result<void>> deleteCustomer(String id) {
    return _repository.deleteCustomer(id);
  }

  Future<Result<List<CustomerLedgerEntry>>> getLedger(String customerId) {
    return _repository.getCustomerLedger(customerId);
  }

  Future<Result<void>> recordPayment({
    required String customerId,
    required double amount,
    required String paymentMode,
    String notes = '',
  }) async {
    if (amount <= 0) {
      return const Result.error(ValidationFailure('Payment amount must be greater than zero'));
    }

    final custRes = await _repository.getCustomerById(customerId);
    if (!custRes.isSuccess || custRes.data == null) {
      return const Result.error(NotFoundFailure('Customer not found'));
    }

    final customer = custRes.data!;
    final newBalance = customer.creditBalance - amount;

    final entry = CustomerLedgerEntry(
      id: const Uuid().v4(),
      customerId: customerId,
      type: LedgerEntryType.paymentReceived,
      amount: amount,
      balanceAfter: newBalance,
      timestamp: DateTime.now(),
      paymentMode: paymentMode,
      notes: notes.isNotEmpty ? notes : 'Payment Received / Balance Settlement',
    );

    return _repository.addLedgerEntry(entry);
  }
}
