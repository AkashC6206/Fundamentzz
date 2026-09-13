class TaxSettings {
  final bool isTaxEnabled;
  final bool isTaxInclusive; // Price entered includes tax
  final String taxName; // 'GST', 'VAT', 'Sales Tax'
  final double defaultTaxRate; // e.g. 5.0%
  final double serviceChargeRate; // e.g. 2.5%
  final bool isServiceChargeEnabled;
  final bool isRoundOffEnabled;

  const TaxSettings({
    this.isTaxEnabled = true,
    this.isTaxInclusive = false,
    this.taxName = 'GST',
    this.defaultTaxRate = 5.0,
    this.serviceChargeRate = 0.0,
    this.isServiceChargeEnabled = false,
    this.isRoundOffEnabled = true,
  });

  TaxSettings copyWith({
    bool? isTaxEnabled,
    bool? isTaxInclusive,
    String? taxName,
    double? defaultTaxRate,
    double? serviceChargeRate,
    bool? isServiceChargeEnabled,
    bool? isRoundOffEnabled,
  }) {
    return TaxSettings(
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      taxName: taxName ?? this.taxName,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      isServiceChargeEnabled: isServiceChargeEnabled ?? this.isServiceChargeEnabled,
      isRoundOffEnabled: isRoundOffEnabled ?? this.isRoundOffEnabled,
    );
  }
}
