import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateInvoiceFromMap(
    Map<String, dynamic> order,
    String shopName, {
    bool share = false,
  }) async {
    final pdf = pw.Document();

    final String id = order['_id'] ?? order['id'] ?? '';
    final String shortId = id.length > 5 ? id.substring(0, 5).toUpperCase() : id.toUpperCase();
    final String invoiceNumber = 'INV-$shortId';

    // Parse Dates
    String dateStr = 'N/A';
    if (order['createdAt'] != null) {
      dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(order['createdAt'].toString()));
    } else if (order['date'] != null) {
      dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(order['date'].toString()));
    }

    String dueStr = 'N/A';
    if (order['deliveryDate'] != null) {
      dueStr = DateFormat('dd MMM yyyy').format(DateTime.parse(order['deliveryDate'].toString()));
    }

    // Customer info
    final String customerName = order['customerName'] ?? 'Walk-in Customer';
    final String customerPhone = order['customerPhone'] ?? order['customer']?['phone'] ?? 'N/A';
    final String customerAddress = order['customer']?['address'] ?? 'N/A';

    // Pricing calculations
    final double price = (order['price'] as num?)?.toDouble() ?? 0.0;
    final bool needsAster = order['needsAster'] ?? false;
    final double asterQty = (order['asterQuantity'] as num?)?.toDouble() ?? 0.0;
    final double asterPrice = (order['asterSellingPrice'] as num?)?.toDouble() ?? 0.0;
    final double liningTotal = needsAster ? (asterQty * asterPrice) : 0.0;
    final double billTotal = price + liningTotal;
    
    final double paidAmount = (order['payment']?['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final double balanceDue = billTotal - paidAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header block
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#6366f1'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'StitchCraft Bespoke Tailoring',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'RETAIL BILL',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Invoice No: $invoiceNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Due Date: $dueStr', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Client vs Merchant Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILLED TO:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            customerName,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 10)),
                          if (customerAddress != 'N/A')
                            pw.Text('Address: $customerAddress', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'MERCHANT:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            shopName,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('StitchCraft Tailoring ERP', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),

                // Table Header
                pw.Table(
                  border: const pw.TableBorder(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Table Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    // Stitching Row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: pw.Text(
                            '${order['apparelType'] ?? 'Custom'} Stitching Service',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: pw.Text('1', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: pw.Text('Rs. ${price.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: pw.Text('Rs. ${price.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                    // Lining Row (if applicable)
                    if (needsAster)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: pw.Text(
                              'Lining (Aster) Material Used',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: pw.Text('${asterQty.toStringAsFixed(1)} m', style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: pw.Text('Rs. ${asterPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: pw.Text('Rs. ${liningTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Calculations Box
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          _pdfTotalRow('Subtotal', 'Rs. ${price.toStringAsFixed(2)}'),
                          if (needsAster)
                            _pdfTotalRow('Lining Stock', 'Rs. ${liningTotal.toStringAsFixed(2)}'),
                          pw.Divider(color: PdfColors.grey300),
                          _pdfTotalRow('Total Bill', 'Rs. ${billTotal.toStringAsFixed(2)}', isBold: true),
                          _pdfTotalRow('Paid Amount', 'Rs. ${paidAmount.toStringAsFixed(2)}'),
                          pw.Divider(color: PdfColors.grey300),
                          _pdfTotalRow(
                            'Balance Due',
                            'Rs. ${balanceDue.toStringAsFixed(2)}',
                            isBold: true,
                            color: PdfColors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing $shopName!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Powered by StitchCraft Bespoke boutique ERP Suite',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final String filename = 'invoice_${shortId.toLowerCase()}.pdf';

    if (share) {
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } else {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: filename);
    }
  }

  static pw.Widget _pdfTotalRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
