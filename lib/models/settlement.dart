/// Represents an explicit debt settlement between roommates/friends.
class Settlement {
  final String id;
  final String roommateName;
  final double amount;
  final DateTime date;
  final String paymentMethod; // 'UPI', 'PhonePe', 'GPay', 'Paytm', 'Cash'
  final String note;

  Settlement({
    required this.id,
    required this.roommateName,
    required this.amount,
    required this.date,
    this.paymentMethod = 'UPI',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roommateName': roommateName,
        'amount': amount,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'note': note,
      };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        roommateName: json['roommateName'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        paymentMethod: (json['paymentMethod'] as String?) ?? 'UPI',
        note: (json['note'] as String?) ?? '',
      );
}

