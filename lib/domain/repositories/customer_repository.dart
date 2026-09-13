import '../../core/utils/result.dart';
import '../entities/customer.dart';
import '../entities/customer_ledger_entry.dart';

abstract class CustomerRepository {
  Future<Result<List<Customer>>> getCustomers({String? searchQuery});
  Future<Result<Customer>> getCustomerById(String id);
  Future<Result<void>> saveCustomer(Customer customer);
  Future<Result<void>> deleteCustomer(String id);

  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(String customerId);
  Future<Result<void>> addLedgerEntry(CustomerLedgerEntry entry);
}
