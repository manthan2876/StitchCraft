import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stitchcraft/core/models/order_model.dart' as order_model;
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateInvoice(order_model.Order order) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(order.orderDate);
    final dueStr = order.dueDate != null ? DateFormat('dd MMM yyyy').format(order.dueDate!) : 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('STITCHCRAFT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(order.customerName),
                        pw.Text('Order ID: ${order.id.substring(0, 8)}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: $dateStr'),
                        pw.Text('Due Date: $dueStr'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(order.description.isEmpty ? order.itemTypes.join(', ') : order.description)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. ${order.totalAmount.toStringAsFixed(2)}')),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${order.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text('Thank you for choosing StitchCraft!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
                pw.Center(child: pw.Text('Modern Bespoke ERP Solutions')),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
