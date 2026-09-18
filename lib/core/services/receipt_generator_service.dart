import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/bill_customizer_settings.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/tax_settings.dart';

class ReceiptGeneratorService {
  Future<Uint8List> generatePdfReceipt({
    required Sale sale,
    required BusinessProfile profile,
    required TaxSettings taxSettings,
    BillCustomizerSettings? customizerSettings,
  }) async {
    final cfg = customizerSettings ?? const BillCustomizerSettings();
    final doc = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final hasHeader = (cfg.showBusinessName && profile.restaurantName.isNotEmpty) ||
        (cfg.showTagline && profile.tagline.isNotEmpty) ||
        (cfg.showAddress && profile.address.isNotEmpty) ||
        (cfg.showPhone && profile.phone.isNotEmpty) ||
        (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty);

    final hasMeta = cfg.showInvoiceNumber ||
        cfg.showDateTime ||
        (cfg.showCustomerDetails && sale.customerName != null && sale.customerName!.isNotEmpty) ||
        cfg.showPaymentMode;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. Store & Header Information
              if (cfg.showBusinessName && profile.restaurantName.isNotEmpty)
                pw.Text(
                  profile.restaurantName.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 15, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              if (cfg.showTagline && profile.tagline.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  profile.tagline,
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (cfg.showAddress && profile.address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  profile.address,
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (cfg.showPhone && profile.phone.isNotEmpty)
                pw.Text(
                  'Phone: ${profile.phone}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              if (cfg.showTaxId && profile.taxRegistrationNumber.isNotEmpty)
                pw.Text(
                  'GSTIN / Tax ID: ${profile.taxRegistrationNumber}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              if (hasHeader) ...[
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              ],

              // 2. Invoice Details & Metadata
              if (cfg.showInvoiceNumber || cfg.showDateTime)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (cfg.showInvoiceNumber)
                      pw.Text('Invoice: #${sale.invoiceNumber}', style: pw.TextStyle(font: fontBold, fontSize: 11))
                    else
                      pw.SizedBox(),
                    if (cfg.showDateTime)
                      pw.Text(dateFormat.format(sale.createdAt), style: pw.TextStyle(font: font, fontSize: 10))
                    else
                      pw.SizedBox(),
                  ],
                ),
              if (cfg.showCustomerDetails && sale.customerName != null && sale.customerName!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(sale.customerName!, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  ],
                ),
              ],
              if (cfg.showPaymentMode) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Mode:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(sale.paymentMode.name.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  ],
                ),
              ],
              if (hasMeta) ...[
                pw.Divider(thickness: 0.8, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
              ],

              // 3. Items Table Header
              if (cfg.showItemPrice)
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('ITEM', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Expanded(flex: 2, child: pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Expanded(flex: 3, child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                  ],
                )
              else
                pw.Row(
                  children: [
                    pw.Expanded(flex: 7, child: pw.Text('ITEM', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Expanded(flex: 3, child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                  ],
                ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),

              // Item Rows
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: cfg.showItemPrice
                      ? pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(item.productName, style: pw.TextStyle(font: font, fontSize: 10)),
                                  if (item.note.isNotEmpty)
                                    pw.Text('(${item.note})', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('${item.quantity.toInt()}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(item.unitPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 10)),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(item.totalAmount.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 10)),
                            ),
                          ],
                        )
                      : pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 7,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(item.productName, style: pw.TextStyle(font: font, fontSize: 10)),
                                  if (item.note.isNotEmpty)
                                    pw.Text('(${item.note})', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('${item.quantity.toInt()}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 10)),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(item.totalAmount.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 10)),
                            ),
                          ],
                        ),
                );
              }),

              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              // 4. Totals & Breakdown
              if (cfg.showSubtotal) ...[
                _buildTotalRow('Subtotal:', '${profile.currencySymbol} ${sale.subtotal.toStringAsFixed(2)}', font, fontBold),
                if (sale.discountAmount > 0)
                  _buildTotalRow('Discount:', '- ${profile.currencySymbol} ${sale.discountAmount.toStringAsFixed(2)}', font, fontBold),
                if (sale.taxAmount > 0)
                  _buildTotalRow('${taxSettings.taxName} (Tax):', '${profile.currencySymbol} ${sale.taxAmount.toStringAsFixed(2)}', font, fontBold),
                if (sale.serviceCharge > 0)
                  _buildTotalRow('Service Charge:', '${profile.currencySymbol} ${sale.serviceCharge.toStringAsFixed(2)}', font, fontBold),
                if (sale.roundOff != 0)
                  _buildTotalRow('Round Off:', '${sale.roundOff > 0 ? "+" : ""}${profile.currencySymbol} ${sale.roundOff.toStringAsFixed(2)}', font, fontBold),
              ],

              if (cfg.showGrandTotal) ...[
                pw.SizedBox(height: 3),
                pw.Divider(thickness: 1.2, color: PdfColors.black),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('GRAND TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                      pw.Text('${profile.currencySymbol} ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1.2, color: PdfColors.black),
              ],

              if (cfg.showCashChange && sale.paymentMode == PaymentMode.cash && sale.cashTendered > 0) ...[
                pw.SizedBox(height: 2),
                _buildTotalRow('Cash Tendered:', '${profile.currencySymbol} ${sale.cashTendered.toStringAsFixed(2)}', font, fontBold),
                _buildTotalRow('Change Returned:', '${profile.currencySymbol} ${sale.changeReturned.toStringAsFixed(2)}', font, fontBold),
              ],

              // QR Code for UPI Payment
              if (cfg.showQrCode && profile.upiVpa.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'upi://pay?pa=${profile.upiVpa}&pn=${Uri.encodeComponent(profile.restaurantName.isNotEmpty ? profile.restaurantName : "Fundamentzz Store")}&am=${sale.totalAmount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('Bill ${sale.invoiceNumber}')}',
                        width: 75,
                        height: 75,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Scan & Pay via UPI',
                        style: pw.TextStyle(font: fontBold, fontSize: 9),
                      ),
                      pw.Text(
                        profile.upiVpa,
                        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],

              if (cfg.showFooter && profile.receiptFooter.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  profile.receiptFooter,
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                'Powered by Fundamentzz POS',
                style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
              
              // 5. Kitchen Order Ticket (KOT)
              if (cfg.showOrderTicketKot) ...[
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1.0, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('*** ORDER TICKET ***', style: pw.TextStyle(font: fontBold, fontSize: 12), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bill No: #${sale.invoiceNumber}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.Text(dateFormat.format(sale.createdAt), style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                if (sale.note.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Ref: ${sale.note}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                ],
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 7, child: pw.Text('ITEM', style: pw.TextStyle(font: fontBold, fontSize: 11))),
                    pw.Expanded(flex: 3, child: pw.Text('QTY', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11))),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                ...sale.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 7,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.productName, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                              if (item.note.isNotEmpty)
                                pw.Text(' * ${item.note}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text('${item.quantity.toInt()}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }),
                pw.Divider(thickness: 1.0, color: PdfColors.black),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildTotalRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> printReceipt({
    required Sale sale,
    required BusinessProfile profile,
    required TaxSettings taxSettings,
    BillCustomizerSettings? customizerSettings,
  }) async {
    final pdfData = await generatePdfReceipt(
      sale: sale,
      profile: profile,
      taxSettings: taxSettings,
      customizerSettings: customizerSettings,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }

  Future<void> shareReceipt({
    required Sale sale,
    required BusinessProfile profile,
    required TaxSettings taxSettings,
    BillCustomizerSettings? customizerSettings,
  }) async {
    final pdfData = await generatePdfReceipt(
      sale: sale,
      profile: profile,
      taxSettings: taxSettings,
      customizerSettings: customizerSettings,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }
}
