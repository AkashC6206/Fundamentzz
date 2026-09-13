class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double creditBalance; // Pending udhaar balance
  final double creditLimit;
  final String notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.creditBalance = 0.0,
    this.creditLimit = 10000.0,
    this.notes = '',
    required this.createdAt,
  });

  bool get hasOutstandingCredit => creditBalance > 0.0;

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditBalance,
    double? creditLimit,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditBalance: creditBalance ?? this.creditBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
