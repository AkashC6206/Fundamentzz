import '../../domain/entities/tax_settings.dart';

class TaxSettingsModel extends TaxSettings {
  const TaxSettingsModel({
    super.isTaxEnabled = true,
    super.isTaxInclusive = false,
    super.taxName = 'GST',
    super.defaultTaxRate = 5.0,
    super.serviceChargeRate = 0.0,
    super.isServiceChargeEnabled = false,
    super.isRoundOffEnabled = true,
  });

  factory TaxSettingsModel.fromEntity(TaxSettings entity) {
    return TaxSettingsModel(
      isTaxEnabled: entity.isTaxEnabled,
      isTaxInclusive: entity.isTaxInclusive,
      taxName: entity.taxName,
      defaultTaxRate: entity.defaultTaxRate,
      serviceChargeRate: entity.serviceChargeRate,
      isServiceChargeEnabled: entity.isServiceChargeEnabled,
      isRoundOffEnabled: entity.isRoundOffEnabled,
    );
  }

  factory TaxSettingsModel.fromMap(Map<String, dynamic> map) {
    return TaxSettingsModel(
      isTaxEnabled: (map['is_tax_enabled'] as int?) != 0,
      isTaxInclusive: (map['is_tax_inclusive'] as int?) != 0,
      taxName: (map['tax_name'] as String?) ?? 'GST',
      defaultTaxRate: (map['default_tax_rate'] as num?)?.toDouble() ?? 5.0,
      serviceChargeRate: (map['service_charge_rate'] as num?)?.toDouble() ?? 0.0,
      isServiceChargeEnabled: (map['is_service_charge_enabled'] as int?) != 0,
      isRoundOffEnabled: (map['is_round_off_enabled'] as int?) != 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'is_tax_enabled': isTaxEnabled ? 1 : 0,
      'is_tax_inclusive': isTaxInclusive ? 1 : 0,
      'tax_name': taxName,
      'default_tax_rate': defaultTaxRate,
      'service_charge_rate': serviceChargeRate,
      'is_service_charge_enabled': isServiceChargeEnabled ? 1 : 0,
      'is_round_off_enabled': isRoundOffEnabled ? 1 : 0,
    };
  }
}
