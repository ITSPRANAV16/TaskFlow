import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches UPI payment apps (GPay, PhonePe, Paytm, BHIM) for roommate debt settlement.
class UpiService {
  /// Opens device UPI application with prefilled payee name, UPI ID, and amount.
  static Future<bool> launchUpiPayment({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    String transactionNote = 'SpendMate Settlement',
  }) async {
    final cleanUpiId = payeeUpiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(transactionNote);
    final formattedAmount = amount.toStringAsFixed(2);

    final upiUrlString =
        'upi://pay?pa=$cleanUpiId&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote';

    final uri = Uri.parse(upiUrlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try direct launch
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching UPI URI: $e');
      return false;
    }
  }
}

