import '../../domain/entities/business_profile.dart';

class BusinessProfileModel extends BusinessProfile {
  const BusinessProfileModel({
    super.restaurantName = 'Fundamentzz Bistro & Cafe',
    super.tagline = 'Innovation Starts with Fundamentals',
    super.address = 'Tech Hub Plaza, Silicon Sector, Bangalore',
    super.phone = '+91 98765 43210',
    super.email = 'contact@fundamentzz.pos',
    super.taxRegistrationNumber = '29ABCDE1234F1Z5',
    super.currencySymbol = '₹',
    super.receiptFooter = 'Thank you for dining with us! Please visit again.',
    super.upiVpa = 'fundamentzz@okhdfcbank',
    super.logoPath,
  });

  factory BusinessProfileModel.fromEntity(BusinessProfile entity) {
    return BusinessProfileModel(
      restaurantName: entity.restaurantName,
      tagline: entity.tagline,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      taxRegistrationNumber: entity.taxRegistrationNumber,
      currencySymbol: entity.currencySymbol,
      receiptFooter: entity.receiptFooter,
      upiVpa: entity.upiVpa,
      logoPath: entity.logoPath,
    );
  }

  factory BusinessProfileModel.fromMap(Map<String, dynamic> map) {
    return BusinessProfileModel(
      restaurantName: (map['restaurant_name'] as String?) ?? 'Fundamentzz Bistro & Cafe',
      tagline: (map['tagline'] as String?) ?? 'Innovation Starts with Fundamentals',
      address: (map['address'] as String?) ?? 'Tech Hub Plaza, Silicon Sector, Bangalore',
      phone: (map['phone'] as String?) ?? '+91 98765 43210',
      email: (map['email'] as String?) ?? 'contact@fundamentzz.pos',
      taxRegistrationNumber: (map['tax_registration_number'] as String?) ?? '29ABCDE1234F1Z5',
      currencySymbol: (map['currency_symbol'] as String?) ?? '₹',
      receiptFooter: (map['receipt_footer'] as String?) ?? 'Thank you for dining with us! Please visit again.',
      upiVpa: (map['upi_vpa'] as String?) ?? 'fundamentzz@okhdfcbank',
      logoPath: map['logo_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'restaurant_name': restaurantName,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_registration_number': taxRegistrationNumber,
      'currency_symbol': currencySymbol,
      'receipt_footer': receiptFooter,
      'upi_vpa': upiVpa,
      'logo_path': logoPath,
    };
  }
}
