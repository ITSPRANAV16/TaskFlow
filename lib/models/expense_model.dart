import 'package:flutter/material.dart';

/// Categories specific to hostel student expenses.
enum ExpenseCategory {
  food,
  mess,
  stationery,
  personal,
  transport,
  recharge,
  medical,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.mess:
        return 'Mess';
      case ExpenseCategory.stationery:
        return 'Stationery';
      case ExpenseCategory.personal:
        return 'Personal';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.recharge:
        return 'Recharge';
      case ExpenseCategory.medical:
        return 'Medical';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.mess:
        return Icons.lunch_dining_rounded;
      case ExpenseCategory.stationery:
        return Icons.edit_note_rounded;
      case ExpenseCategory.personal:
        return Icons.person_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.recharge:
        return Icons.phone_android_rounded;
      case ExpenseCategory.medical:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF59E0B); // Amber
      case ExpenseCategory.mess:
        return const Color(0xFF14B8A6); // Teal
      case ExpenseCategory.stationery:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.personal:
        return const Color(0xFF8B5CF6); // Violet
      case ExpenseCategory.transport:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.recharge:
        return const Color(0xFF06B6D4); // Cyan
      case ExpenseCategory.medical:
        return const Color(0xFFF43F5E); // Rose
      case ExpenseCategory.other:
        return const Color(0xFF64748B); // Slate
    }
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;
  final bool isShared;
  final String paidBy;
  final List<String> splitWith;
  final bool isRecurring;
  final String recurringFrequency;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.isShared = false,
    this.paidBy = 'You',
    this.splitWith = const ['You'],
    this.isRecurring = false,
    this.recurringFrequency = 'monthly',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalSplitMembers =>
      (isShared && splitWith.isNotEmpty) ? splitWith.length : 1;

  double get sharePerPerson => amount / totalSplitMembers;

  bool get didIPay {
    final lower = paidBy.trim().toLowerCase();
    return !isShared || lower == 'you' || lower == 'self' || lower == 'me';
  }

  /// The portion that belongs to personal budget.
  double get myShare => isShared ? sharePerPerson : amount;

  /// Amount that roommates owe you if you paid for the whole group.
  double get amountOthersOweMe {
    if (!isShared || !didIPay) return 0.0;
    return amount - sharePerPerson;
  }

  /// Amount you owe if someone else paid for the group.
  double get amountIOweOthers {
    if (!isShared || didIPay) return 0.0;
    return sharePerPerson;
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    bool? isShared,
    String? paidBy,
    List<String>? splitWith,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isShared: isShared ?? this.isShared,
      paidBy: paidBy ?? this.paidBy,
      splitWith: splitWith ?? this.splitWith,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note,
      'isShared': isShared,
      'paidBy': paidBy,
      'splitWith': splitWith,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      isShared: json['isShared'] as bool? ?? false,
      paidBy: json['paidBy'] as String? ?? 'You',
      splitWith: (json['splitWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['You'],
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String? ?? 'monthly',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
