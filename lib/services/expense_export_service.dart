import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/expense_model.dart';

class ExpenseExportService {
  /// Generates a standardized CSV document from monthly transactions.
  static String generateCsv({
    required DateTime month,
    required List<Expense> expenses,
    required double monthlyBudget,
    required double totalSpent,
    required double remainingBudget,
  }) {
    final monthName = DateFormat('MMMM yyyy').format(month);
    final buffer = StringBuffer();

    // Summary Header
    buffer.writeln('# Hostel Expense Report - $monthName');
    buffer.writeln('# Monthly Budget: ₹${monthlyBudget.toStringAsFixed(2)}');
    buffer.writeln('# Total Spent: ₹${totalSpent.toStringAsFixed(2)}');
    buffer.writeln('# Remaining Savings: ₹${remainingBudget.toStringAsFixed(2)}');
    buffer.writeln('# Total Transactions: ${expenses.length}');
    buffer.writeln('');

    // Column Headers
    buffer.writeln(
      'Date,Time,Title,Category,Total Amount (INR),Your Share (INR),Is Shared,Paid By,Split With,Recurring,Note',
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('hh:mm a');

    for (final e in expenses) {
      final dateStr = dateFormat.format(e.date);
      final timeStr = timeFormat.format(e.date);
      final titleStr = _escapeCsv(e.title);
      final categoryStr = _escapeCsv(e.category.label);
      final totalAmountStr = e.amount.toStringAsFixed(2);
      final myShareStr = e.myShare.toStringAsFixed(2);
      final isSharedStr = e.isShared ? 'Yes' : 'No';
      final paidByStr = _escapeCsv(e.paidBy);
      final splitWithStr = _escapeCsv(e.splitWith.join('; '));
      final isRecurringStr = e.isRecurring ? 'Yes' : 'No';
      final noteStr = _escapeCsv(e.note);

      buffer.writeln(
        '$dateStr,$timeStr,$titleStr,$categoryStr,$totalAmountStr,$myShareStr,$isSharedStr,$paidByStr,$splitWithStr,$isRecurringStr,$noteStr',
      );
    }

    return buffer.toString();
  }

  /// Generates a human-friendly formatted summary suitable for WhatsApp or parent updates.
  static String generateParentSummaryText({
    required DateTime month,
    required List<Expense> expenses,
    required double monthlyBudget,
    required double totalSpent,
    required double remainingBudget,
    required Map<ExpenseCategory, double> categoryBreakdown,
    required Map<String, double> roommateBalances,
  }) {
    final monthName = DateFormat('MMMM yyyy').format(month);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final buffer = StringBuffer();
    buffer.writeln('📊 Hostel Expense Summary - $monthName');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    if (monthlyBudget > 0) {
      buffer.writeln('💰 Monthly Budget: ${fmt.format(monthlyBudget)}');
      buffer.writeln('🛒 Total Spent:    ${fmt.format(totalSpent)}');
      if (remainingBudget >= 0) {
        buffer.writeln('💵 Money Saved:    ${fmt.format(remainingBudget)}');
      } else {
        buffer.writeln('⚠️ Over Budget:    -${fmt.format(remainingBudget.abs())}');
      }
    } else {
      buffer.writeln('🛒 Total Spent:    ${fmt.format(totalSpent)}');
    }
    buffer.writeln('📝 Total Entries:  ${expenses.length}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');

    if (categoryBreakdown.isNotEmpty) {
      buffer.writeln('📂 Category Breakdown:');
      for (final entry in categoryBreakdown.entries) {
        final percent = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
        buffer.writeln(
          '• ${entry.key.label}: ${fmt.format(entry.value)} (${percent.toStringAsFixed(0)}%)',
        );
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    }

    if (roommateBalances.isNotEmpty) {
      buffer.writeln('👥 Roommate Split Balances:');
      for (final entry in roommateBalances.entries) {
        final owes = entry.value;
        if (owes > 0) {
          buffer.writeln('• ${entry.key} owes you ${fmt.format(owes)}');
        } else if (owes < 0) {
          buffer.writeln('• You owe ${entry.key} ${fmt.format(owes.abs())}');
        } else {
          buffer.writeln('• ${entry.key}: Settled');
        }
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    }

    buffer.writeln('Generated via SpendMate');
    return buffer.toString();
  }

  /// Saves CSV file to application documents directory and returns its path.
  static Future<String> saveCsvToDevice({
    required String csvContent,
    required DateTime month,
  }) async {
    final monthSlug = DateFormat('yyyy_MM').format(month);
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/hostel_expenses_$monthSlug.csv';
    final file = File(filePath);
    await file.writeAsString(csvContent);
    return filePath;
  }

  /// Shares roommate balance ledger via WhatsApp or default share handler.
  static Future<void> shareRoommateBalances(Map<String, double> balances) async {
    final buffer = StringBuffer();
    buffer.writeln('📋 *SpendMate - रूममेट हिशोब (Roommate Splits)*');
    buffer.writeln('--------------------------------');
    for (final entry in balances.entries) {
      final name = entry.key;
      final bal = entry.value;
      if (bal > 0) {
        buffer.writeln('• $name: ₹${bal.toStringAsFixed(0)} (येणे बाकी / Owed to me)');
      } else {
        buffer.writeln('• $name: ₹${bal.abs().toStringAsFixed(0)} (देणे बाकी / I owe)');
      }
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Generated via SpendMate');
    final text = Uri.encodeComponent(buffer.toString());
    final uri = Uri.parse('whatsapp://send?text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}

