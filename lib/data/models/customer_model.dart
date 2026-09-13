import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email = '',
    super.address = '',
    super.creditBalance = 0.0,
    super.creditLimit = 10000.0,
    super.notes = '',
    required super.createdAt,
  });

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      creditBalance: customer.creditBalance,
      creditLimit: customer.creditLimit,
      notes: customer.notes,
      createdAt: customer.createdAt,
    );
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      creditBalance: (map['credit_balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 10000.0,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'credit_balance': creditBalance,
      'credit_limit': creditLimit,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
