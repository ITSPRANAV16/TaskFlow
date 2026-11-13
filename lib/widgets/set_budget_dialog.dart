import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class SetBudgetDialog extends StatefulWidget {
  const SetBudgetDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<ExpenseProvider>(context, listen: false),
        child: const SetBudgetDialog(),
      ),
    );
  }

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final budget = context.read<ExpenseProvider>().monthlyBudget;
    _controller = TextEditingController(
      text: budget > 0 ? budget.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final value = double.tryParse(_controller.text.trim());
    if (value != null && value > 0) {
      context.read<ExpenseProvider>().setMonthlyBudget(value);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: AppTheme.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Monthly Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your monthly spending limit to track savings.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onSubmitted: (_) => _saveBudget(),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
              hintText: 'e.g. 5000',
              filled: true,
              fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
              ),
            ),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Quick-set chips
          Wrap(
            spacing: 8,
            children: [2000, 3000, 5000, 8000, 10000].map((amount) {
              return ActionChip(
                label: Text(
                  '₹$amount',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                onPressed: () {
                  _controller.text = amount.toString();
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: _saveBudget,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save Budget'),
        ),
      ],
    );
  }
}
