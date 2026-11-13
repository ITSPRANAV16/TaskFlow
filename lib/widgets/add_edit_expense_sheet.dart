import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class AddEditExpenseSheet extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddEditExpenseSheet({super.key, this.expenseToEdit});

  @override
  State<AddEditExpenseSheet> createState() => _AddEditExpenseSheetState();
}

class _AddEditExpenseSheetState extends State<AddEditExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _memberController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();
  bool _isShared = false;
  String _paidBy = 'You';
  List<String> _splitWith = ['You'];
  bool _isRecurring = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.expenseToEdit!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(
          e.amount == e.amount.roundToDouble() ? 0 : 2);
      _noteController.text = e.note;
      _selectedCategory = e.category;
      _selectedDate = e.date;
      _isShared = e.isShared;
      _paidBy = e.paidBy;
      _splitWith = List<String>.from(e.splitWith);
      _isRecurring = e.isRecurring;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addSplitMember() {
    final name = _memberController.text.trim();
    if (name.isNotEmpty && !_splitWith.contains(name)) {
      setState(() {
        _splitWith.add(name);
        _memberController.clear();
      });
    }
  }

  void _removeSplitMember(String name) {
    if (_splitWith.length > 1) {
      setState(() {
        _splitWith.remove(name);
        if (_paidBy == name) {
          _paidBy = 'You';
        }
      });
    }
  }

  void _saveExpense() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();

    if (_isEditing) {
      provider.updateExpense(widget.expenseToEdit!.copyWith(
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
        isShared: _isShared,
        paidBy: _paidBy,
        splitWith: _isShared ? _splitWith : const ['You'],
        isRecurring: _isRecurring,
      ));
    } else {
      provider.addExpense(Expense(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
        isShared: _isShared,
        paidBy: _paidBy,
        splitWith: _isShared ? _splitWith : const ['You'],
        isRecurring: _isRecurring,
      ));
    }

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryTeal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final sharePerPerson = _splitWith.isNotEmpty ? parsedAmount / _splitWith.length : parsedAmount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      color: AppTheme.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Expense' : 'Add Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount Field (prominent)
              _buildLabel('Amount', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: !_isEditing,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal.withOpacity(0.8),
                  ),
                  hintText: '0',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              _buildLabel('Title', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Lunch at canteen, Room Wi-Fi',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector
              _buildLabel('Category', isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withOpacity(0.15)
                            : (isDark ? AppTheme.darkSurface : AppTheme.lightCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? cat.color
                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date Picker
              _buildLabel('Date', isDark),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppTheme.primaryTeal,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Roommate Bill Splitting Toggle ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isShared
                        ? AppTheme.primaryTeal.withOpacity(0.5)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_rounded,
                          size: 20,
                          color: _isShared ? AppTheme.primaryTeal : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Split with Roommates',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Split bill equally across room members',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isShared,
                          activeColor: AppTheme.primaryTeal,
                          onChanged: (val) {
                            setState(() {
                              _isShared = val;
                              if (val && _splitWith.length < 2) {
                                _splitWith = ['You', 'Roommate 1'];
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    if (_isShared) ...[
                      const Divider(height: 20),
                      // Who Paid Row
                      Row(
                        children: [
                          Text(
                            'Paid by: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _splitWith.contains(_paidBy) ? _paidBy : 'You',
                            dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                            items: _splitWith.map((m) {
                              return DropdownMenuItem(value: m, child: Text(m));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paidBy = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Members chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _splitWith.map((member) {
                          final isYou = member == 'You';
                          return Chip(
                            label: Text(member, style: const TextStyle(fontSize: 12)),
                            backgroundColor: isYou
                                ? AppTheme.primaryTeal.withOpacity(0.15)
                                : (isDark ? AppTheme.darkCard : const Color(0xFFE2E8F0)),
                            deleteIcon: isYou ? null : const Icon(Icons.close, size: 14),
                            onDeleted: isYou ? null : () => _removeSplitMember(member),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Add member input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _memberController,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add roommate name...',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: isDark ? AppTheme.darkCard : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addSplitMember(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: _addSplitMember,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Split Preview Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${parsedAmount.toStringAsFixed(0)} ÷ ${_splitWith.length} people = ₹${sharePerPerson.toStringAsFixed(0)} each',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Recurring Toggle ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 20,
                      color: _isRecurring ? AppTheme.primaryViolet : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Recurring Bill',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'e.g. Mess Fee, Room Rent, Wi-Fi',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      activeColor: AppTheme.primaryViolet,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note (optional)
              _buildLabel('Note (optional)', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Any additional details...',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saveExpense,
                  icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
                  label: Text(
                    _isEditing ? 'Update Expense' : 'Add Expense',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }
}
