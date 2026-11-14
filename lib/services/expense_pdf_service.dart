import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/expense_model.dart';
import '../models/settlement.dart';

/// Generates publication-quality PDF financial statements for SpendMate.
class ExpensePdfService {
  static Future<void> generateAndShareMonthlyReport({
    required DateTime month,
    required List<Expense> expenses,
    required List<Settlement> settlements,
    required double monthlyBudget,
    required double totalSpent,
    required double personalShare,
    required Map<String, double> categoryBreakdown,
    required Map<String, double> roommateBalances,
    String userName = 'SpendMate User',
  }) async {
    final pdf = pw.Document();
    final monthStr = DateFormat('MMMM yyyy').format(month);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    // Primary & Accent styling
    final primaryColor = PdfColor.fromHex('#4F46E5'); // Indigo
    final secondaryColor = PdfColor.fromHex('#10B981'); // Emerald
    final darkHeader = PdfColor.fromHex('#0F172A'); // Slate

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SpendMate',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Monthly Expense & Split Financial Statement',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      monthStr,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: darkHeader,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Account: $userName',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.SizedBox(height: 12),

            // Summary Metrics Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell('Monthly Budget', currencyFormat.format(monthlyBudget), primaryColor),
                  _buildMetricCell('Total Spent', currencyFormat.format(totalSpent), darkHeader),
                  _buildMetricCell('Personal Share', currencyFormat.format(personalShare), secondaryColor),
                  _buildMetricCell(
                    'Budget Remaining',
                    currencyFormat.format((monthlyBudget - totalSpent).clamp(0, double.infinity)),
                    (monthlyBudget > 0 && totalSpent > monthlyBudget) ? PdfColors.red : secondaryColor,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Category Breakdown Table
            if (categoryBreakdown.isNotEmpty) ...[
              pw.Text(
                'Category Breakdown',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkHeader),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Category', 'Amount', '% of Total'],
                data: categoryBreakdown.entries.map((entry) {
                  final pct = totalSpent > 0 ? (entry.value / totalSpent * 100).toStringAsFixed(1) : '0';
                  return [entry.key, currencyFormat.format(entry.value), '$pct%'];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              pw.SizedBox(height: 18),
            ],

            // Roommate Balances Table
            if (roommateBalances.isNotEmpty) ...[
              pw.Text(
                'Roommate Split Summary',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkHeader),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Roommate / Friend', 'Status', 'Balance'],
                data: roommateBalances.entries.map((entry) {
                  final absVal = entry.value.abs();
                  final status = absVal <= 0.01
                      ? 'All Settled'
                      : (entry.value > 0 ? 'Owes You' : 'You Owe');
                  return [entry.key, status, currencyFormat.format(absVal)];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#334155')),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              pw.SizedBox(height: 18),
            ],

            // Detailed Expenses Table
            pw.Text(
              'Detailed Transaction Ledger (${expenses.length} Records)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkHeader),
            ),
            pw.SizedBox(height: 6),
            if (expenses.isEmpty)
              pw.Text('No transactions recorded for this month.', style: const pw.TextStyle(color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Mode', 'Amount'],
                data: expenses.map((e) {
                  return [
                    DateFormat('d MMM').format(e.date),
                    e.title,
                    e.category.label,
                    e.isShared ? 'Shared' : 'Personal',
                    currencyFormat.format(e.amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SpendMate • Personal & Hostel Finance Statement',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Developed by Pranav Patil',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
              ],
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'SpendMate_Statement_${DateFormat('yyyy_MM').format(month)}.pdf',
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
    }
  }

  static pw.Widget _buildMetricCell(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

