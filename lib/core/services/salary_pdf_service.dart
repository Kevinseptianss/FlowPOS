import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/staff/data/models/salary_report_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class SalaryPdfService {
  static Future<void> generateAndShareSlip(SalaryReportModel report) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    final dateFormat = DateFormat('dd MMM yyyy');
    final periodStr = '${dateFormat.format(report.periodStart)} - ${dateFormat.format(report.periodEnd)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('FLOW POS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Slip Gaji Karyawan', style: pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildInfoRow('Nama Karyawan', report.staffName),
                _buildInfoRow('Periode', periodStr),
                _buildInfoRow('Tanggal Cetak', dateFormat.format(report.createdAt)),
                pw.SizedBox(height: 20),
                pw.Text('Rincian Pembayaran:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildAmountRow('Gaji Pokok / Shift', report.basePay),
                if (report.bonus > 0) _buildAmountRow('Bonus / Insentif', report.bonus, color: PdfColors.green),
                if (report.debt > 0) _buildAmountRow('Potongan / Kasbon', -report.debt, color: PdfColors.red),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL DITERIMA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text(formatRupiah(report.netPay), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (report.notes != null) ...[
                  pw.SizedBox(height: 20),
                  pw.Text('Catatan:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(report.notes!, style: pw.TextStyle(fontSize: 10)),
                ],
                pw.Spacer(),
                pw.Center(
                  child: pw.Text('Terima kasih atas kerja keras Anda!', style: pw.TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Slip_Gaji_${report.staffName}_${report.periodStart.day}.pdf');
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label)),
          pw.Text(': '),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountRow(String label, int amount, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            formatRupiah(amount),
            style: pw.TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
