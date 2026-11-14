import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/expense_export_service.dart';
import '../services/upi_service.dart';

class RoommatesScreen extends StatefulWidget {
  const RoommatesScreen({super.key});

  @override
  State<RoommatesScreen> createState() => _RoommatesScreenState();
}

class _RoommatesScreenState extends State<RoommatesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final balances = provider.roommateBalances;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'रूममेट हिशोब (Roommate Splits & UPI)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'WhatsApp वर हिशोब पाठवा',
            icon: const Icon(Icons.share_rounded),
            onPressed: balances.isEmpty
                ? null
                : () => ExpenseExportService.shareRoommateBalances(balances),
          ),
        ],
      ),
      body: balances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'या महिन्यात कोणताही रूममेट हिशोब बाकी नाही',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Banner
                  _buildSummaryBanner(provider, isDark),
                  const SizedBox(height: 16),

                  const Text(
                    'मित्र व रूममेट्सचा हिशोब',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Roommate Cards
                  ...balances.entries.map((entry) {
                    return _buildRoommateTile(
                      name: entry.key,
                      balance: entry.value,
                      provider: provider,
                      isDark: isDark,
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryBanner(ExpenseProvider provider, bool isDark) {
    final owedToMe = provider.totalOwedToMe;
    final iOwe = provider.totalIOweOthers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'इतरांकडून येणे बाकी',
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${owedToMe.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'तुम्ही देणे बाकी',
                  style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${iOwe.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoommateTile({
    required String name,
    required double balance,
    required ExpenseProvider provider,
    required bool isDark,
  }) {
    final theyOweMe = balance > 0;
    final absBalance = balance.abs();
    final statusColor =
        theyOweMe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.15),
                foregroundColor: statusColor,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      theyOweMe
                          ? 'यांच्याकडून ₹${absBalance.toStringAsFixed(0)} येणे आहे'
                          : 'यांना ₹${absBalance.toStringAsFixed(0)} देणे आहे',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${absBalance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // UPI Payment Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUpiDialog(name, absBalance),
                  icon: const Icon(Icons.account_balance_wallet_rounded,
                      size: 16),
                  label: const Text('UPI द्वारे भरा (GPay/PhonePe)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mark Settled Button
              IconButton.filledTonal(
                tooltip: 'हिशोब पूर्ण नोंदवा',
                icon: const Icon(Icons.check_rounded, size: 20),
                onPressed: () {
                  provider.recordSettlement(name, absBalance);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ $name सोबतचा ₹${absBalance.toStringAsFixed(0)} हिशोब पूर्ण झाला',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpiDialog(String name, double amount) {
    final upiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name ला UPI पेमेंट करा'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'रक्कम: ₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(
                labelText: 'मित्राचा UPI ID (उदा. 9876543210@paytm)',
                hintText: 'user@okhdfcbank',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (upiCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await UpiService.launchUpiPayment(
                  payeeUpiId: upiCtrl.text.trim(),
                  payeeName: name,
                  amount: amount,
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('UPI अ‍ॅप उघडा'),
          ),
        ],
      ),
    );
  }
}

