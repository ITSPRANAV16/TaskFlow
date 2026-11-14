import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
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
    final loc = context.watch<LocaleProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final balances = provider.roommateBalances;
    final settlements = provider.currentMonthSettlements;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('roommate_splits'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: loc.tr('share_whatsapp'),
            icon: const Icon(Icons.share_rounded),
            onPressed: balances.isEmpty
                ? null
                : () => ExpenseExportService.shareRoommateBalances(balances),
          ),
        ],
      ),
      body: (balances.isEmpty && settlements.isEmpty)
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
                    loc.tr('no_splits'),
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
                  _buildSummaryBanner(provider, loc, isDark),
                  const SizedBox(height: 20),

                  Text(
                    loc.tr('roommate_summary'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Roommate Cards
                  if (balances.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.tr('settled_badge'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...balances.entries.map((entry) {
                      return _buildRoommateTile(
                        name: entry.key,
                        balance: entry.value,
                        provider: provider,
                        loc: loc,
                        isDark: isDark,
                      );
                    }),

                  const SizedBox(height: 24),

                  // Settlement History
                  if (settlements.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.history_rounded,
                            size: 20, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('settlement_history'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...settlements.map((s) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.roommateName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${s.paymentMethod} • ${DateFormat('d MMM, h:mm a').format(s.date)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${s.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.undo_rounded, size: 18),
                              tooltip: 'Undo',
                              onPressed: () {
                                provider.deleteSettlement(s.id);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryBanner(
      ExpenseProvider provider, LocaleProvider loc, bool isDark) {
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
                Text(
                  loc.tr('they_owe_you'),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
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
                Text(
                  loc.tr('you_owe_them'),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
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
    required LocaleProvider loc,
    required bool isDark,
  }) {
    final absBalance = balance.abs();
    final isSettled = absBalance <= 0.01;
    final theyOweMe = balance > 0.01;
    final statusColor = isSettled
        ? Colors.grey
        : (theyOweMe ? const Color(0xFF10B981) : const Color(0xFFEF4444));

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
                      isSettled
                          ? loc.tr('settled_badge')
                          : (theyOweMe
                              ? '${loc.tr('they_owe_you')} ₹${absBalance.toStringAsFixed(0)}'
                              : '${loc.tr('you_owe_them')} ₹${absBalance.toStringAsFixed(0)}'),
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
          if (!isSettled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // UPI / Phone Payment Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpiPhoneDialog(name, absBalance),
                    icon: const Icon(Icons.phone_android_rounded, size: 16),
                    label: Text(
                      loc.tr('pay_via_upi_phone'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mark Settled Button
                IconButton.filledTonal(
                  tooltip: loc.tr('mark_settled'),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  onPressed: () {
                    provider.recordSettlement(
                      name,
                      absBalance,
                      paymentMethod: 'Settled',
                      note: 'Marked as Done',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ ${loc.tr('settlement_recorded')}: $name (₹${absBalance.toStringAsFixed(0)})',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showUpiPhoneDialog(String name, double amount) async {
    final savedHandle = await UpiService.getSavedRoommateHandle(name);
    if (!mounted) return;

    final inputCtrl = TextEditingController(text: savedHandle ?? '');
    String selectedHandle = '@okaxis'; // Default to GPay / UPI

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isPhone = !inputCtrl.text.contains('@') &&
              inputCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10;

          return AlertDialog(
            title: Text('Pay $name (₹${amount.toStringAsFixed(0)})'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter 10-digit Mobile Number or full UPI ID:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: inputCtrl,
                    keyboardType: TextInputType.text,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Phone Number / UPI ID',
                      hintText: 'e.g. 9876543210 or user@upi',
                      prefixIcon: Icon(
                        isPhone ? Icons.phone_rounded : Icons.alternate_email,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (!inputCtrl.text.contains('@')) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Choose Payment App / Provider:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: UpiService.popularHandles.map((item) {
                        final handle = item['handle']!;
                        final label = item['name']!;
                        final isSelected = selectedHandle == handle;
                        return ChoiceChip(
                          label: Text(label,
                              style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (sel) {
                            if (sel) {
                              setDialogState(() {
                                selectedHandle = handle;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final text = inputCtrl.text.trim();
                  if (text.isNotEmpty) {
                    await UpiService.saveRoommateHandle(name, text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    await UpiService.launchUpiPayment(
                      payeeInput: text,
                      payeeName: name,
                      amount: amount,
                      defaultHandle: selectedHandle,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open UPI App'),
              ),
            ],
          );
        },
      ),
    );
  }
}
