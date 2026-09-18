class BillCustomizerSettings {
  final bool showBusinessName;
  final bool showTagline;
  final bool showAddress;
  final bool showPhone;
  final bool showTaxId;
  final bool showInvoiceNumber;
  final bool showDateTime;
  final bool showCustomerDetails;
  final bool showPaymentMode;
  final bool showItemPrice;
  final bool showSubtotal;
  final bool showGrandTotal;
  final bool showCashChange;
  final bool showFooter;
  final bool showOrderTicketKot;
  final bool cutPaper;
  final bool showQrCode;

  const BillCustomizerSettings({
    this.showBusinessName = true,
    this.showTagline = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showTaxId = true,
    this.showInvoiceNumber = true,
    this.showDateTime = true,
    this.showCustomerDetails = true,
    this.showPaymentMode = true,
    this.showItemPrice = true,
    this.showSubtotal = true,
    this.showGrandTotal = true,
    this.showCashChange = true,
    this.showFooter = true,
    this.showOrderTicketKot = true,
    this.cutPaper = true,
    this.showQrCode = true,
  });

  BillCustomizerSettings copyWith({
    bool? showBusinessName,
    bool? showTagline,
    bool? showAddress,
    bool? showPhone,
    bool? showTaxId,
    bool? showInvoiceNumber,
    bool? showDateTime,
    bool? showCustomerDetails,
    bool? showPaymentMode,
    bool? showItemPrice,
    bool? showSubtotal,
    bool? showGrandTotal,
    bool? showCashChange,
    bool? showFooter,
    bool? showOrderTicketKot,
    bool? cutPaper,
    bool? showQrCode,
  }) {
    return BillCustomizerSettings(
      showBusinessName: showBusinessName ?? this.showBusinessName,
      showTagline: showTagline ?? this.showTagline,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showTaxId: showTaxId ?? this.showTaxId,
      showInvoiceNumber: showInvoiceNumber ?? this.showInvoiceNumber,
      showDateTime: showDateTime ?? this.showDateTime,
      showCustomerDetails: showCustomerDetails ?? this.showCustomerDetails,
      showPaymentMode: showPaymentMode ?? this.showPaymentMode,
      showItemPrice: showItemPrice ?? this.showItemPrice,
      showSubtotal: showSubtotal ?? this.showSubtotal,
      showGrandTotal: showGrandTotal ?? this.showGrandTotal,
      showCashChange: showCashChange ?? this.showCashChange,
      showFooter: showFooter ?? this.showFooter,
      showOrderTicketKot: showOrderTicketKot ?? this.showOrderTicketKot,
      cutPaper: cutPaper ?? this.cutPaper,
      showQrCode: showQrCode ?? this.showQrCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'show_business_name': showBusinessName ? 1 : 0,
      'show_tagline': showTagline ? 1 : 0,
      'show_address': showAddress ? 1 : 0,
      'show_phone': showPhone ? 1 : 0,
      'show_tax_id': showTaxId ? 1 : 0,
      'show_invoice_number': showInvoiceNumber ? 1 : 0,
      'show_date_time': showDateTime ? 1 : 0,
      'show_customer_details': showCustomerDetails ? 1 : 0,
      'show_payment_mode': showPaymentMode ? 1 : 0,
      'show_item_price': showItemPrice ? 1 : 0,
      'show_subtotal': showSubtotal ? 1 : 0,
      'show_grand_total': showGrandTotal ? 1 : 0,
      'show_cash_change': showCashChange ? 1 : 0,
      'show_footer': showFooter ? 1 : 0,
      'show_order_ticket_kot': showOrderTicketKot ? 1 : 0,
      'cut_paper': cutPaper ? 1 : 0,
      'show_qr_code': showQrCode ? 1 : 0,
    };
  }

  static bool _parseBool(dynamic val, {bool defaultValue = true}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final lower = val.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  factory BillCustomizerSettings.fromMap(Map<String, dynamic> map) {
    return BillCustomizerSettings(
      showBusinessName: _parseBool(map['show_business_name']),
      showTagline: _parseBool(map['show_tagline']),
      showAddress: _parseBool(map['show_address']),
      showPhone: _parseBool(map['show_phone']),
      showTaxId: _parseBool(map['show_tax_id']),
      showInvoiceNumber: _parseBool(map['show_invoice_number']),
      showDateTime: _parseBool(map['show_date_time']),
      showCustomerDetails: _parseBool(map['show_customer_details']),
      showPaymentMode: _parseBool(map['show_payment_mode']),
      showItemPrice: _parseBool(map['show_item_price']),
      showSubtotal: _parseBool(map['show_subtotal']),
      showGrandTotal: _parseBool(map['show_grand_total']),
      showCashChange: _parseBool(map['show_cash_change']),
      showFooter: _parseBool(map['show_footer']),
      showOrderTicketKot: _parseBool(map['show_order_ticket_kot']),
      cutPaper: _parseBool(map['cut_paper']),
      showQrCode: _parseBool(map['show_qr_code']),
    );
  }
}
