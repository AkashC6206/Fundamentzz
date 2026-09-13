class BusinessProfile {
  final String restaurantName;
  final String tagline;
  final String address;
  final String phone;
  final String email;
  final String taxRegistrationNumber; // GSTIN / Tax ID
  final String currencySymbol;
  final String receiptFooter;
  final String upiVpa; // e.g. fundamentzz@upi for quick QR generation
  final String? logoPath;

  const BusinessProfile({
    this.restaurantName = 'Fundamentzz Bistro & Cafe',
    this.tagline = 'Innovation Starts with Fundamentals',
    this.address = 'Tech Hub Plaza, Silicon Sector, Bangalore',
    this.phone = '+91 98765 43210',
    this.email = 'contact@fundamentzz.pos',
    this.taxRegistrationNumber = '29ABCDE1234F1Z5',
    this.currencySymbol = '₹',
    this.receiptFooter = 'Thank you for dining with us! Please visit again.',
    this.upiVpa = 'fundamentzz@okhdfcbank',
    this.logoPath,
  });

  BusinessProfile copyWith({
    String? restaurantName,
    String? tagline,
    String? address,
    String? phone,
    String? email,
    String? taxRegistrationNumber,
    String? currencySymbol,
    String? receiptFooter,
    String? upiVpa,
    String? logoPath,
  }) {
    return BusinessProfile(
      restaurantName: restaurantName ?? this.restaurantName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxRegistrationNumber: taxRegistrationNumber ?? this.taxRegistrationNumber,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      upiVpa: upiVpa ?? this.upiVpa,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
