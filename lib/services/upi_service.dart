import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for launching UPI payments via Mobile Phone Number or UPI ID.
class UpiService {
  static const String _handlePrefix = 'spendmate_upi_handle_';

  static const List<Map<String, String>> popularHandles = [
    {'name': 'Google Pay', 'handle': '@okaxis'},
    {'name': 'PhonePe', 'handle': '@ybl'},
    {'name': 'Paytm', 'handle': '@paytm'},
    {'name': 'BHIM / Any UPI', 'handle': '@upi'},
  ];

  /// Resolves raw input (either full UPI ID or 10-digit mobile number) into a standard UPI VPA.
  static String formatVpa(String input, {String handle = '@upi'}) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }

    // Clean non-digit characters (e.g., spaces, +91)
    String digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
      digitsOnly = digitsOnly.substring(2);
    }
    return '$digitsOnly$handle';
  }

  /// Launches Android UPI intent for the resolved payment target.
  static Future<bool> launchUpiPayment({
    required String payeeInput,
    required String payeeName,
    required double amount,
    String defaultHandle = '@upi',
    String transactionNote = 'SpendMate Settlement',
  }) async {
    final cleanVpa = formatVpa(payeeInput, handle: defaultHandle);
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(transactionNote);
    final formattedAmount = amount.toStringAsFixed(2);

    final upiUrlString =
        'upi://pay?pa=$cleanVpa&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote';

    final uri = Uri.parse(upiUrlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching UPI URI: $e');
      return false;
    }
  }

  /// Get stored phone number or UPI ID for a specific roommate
  static Future<String?> getSavedRoommateHandle(String roommate) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_handlePrefix${roommate.trim().toLowerCase()}');
  }

  /// Save phone number or UPI ID for a specific roommate for quick future settlements
  static Future<void> saveRoommateHandle(String roommate, String handle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_handlePrefix${roommate.trim().toLowerCase()}',
      handle.trim(),
    );
  }
}
