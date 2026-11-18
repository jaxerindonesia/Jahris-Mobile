class PettyCashRecord {
  const PettyCashRecord({
    this.id,
    this.employeeName,
    this.purpose,
    this.category,
    this.amount,
    this.date,
    this.status,
    this.type,
  });

  final String? id;
  final String? employeeName;
  final String? purpose;
  final String? category;
  final num? amount;
  final DateTime? date;
  final String? status;

  /// Jenis transaksi: `in` (kas masuk / top up) atau `out` (kas keluar).
  final String? type;

  bool get isIncome {
    final value = (type ?? category ?? purpose ?? '').toLowerCase();
    return value == 'in' ||
        value.contains('masuk') ||
        value.contains('income') ||
        value.contains('top up') ||
        value.contains('topup');
  }

  // Terverifikasi dari GET /pettycash pada 21 Oktober 2026.
  factory PettyCashRecord.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] ?? json['user'];
    return PettyCashRecord(
      id: _text(json['id'] ?? json['_id']),
      employeeName: _text(
        json['employeeName'] ??
            json['employee_name'] ??
            (employee is Map<String, dynamic>
                ? employee['name'] ?? employee['fullName']
                : employee),
      ),
      purpose: _text(json['purpose'] ?? json['description'] ?? json['title']),
      category: _text(json['category'] ?? json['type']),
      amount: _number(json['amount'] ?? json['nominal'] ?? json['total']),
      date: _date(json['transferDate'] ?? json['date'] ?? json['createdAt']),
      status: _text(json['status']),
      type: _text(json['transactionType'] ?? json['flow'] ?? json['direction']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeName != null) 'employeeName': employeeName,
    if (purpose != null) 'purpose': purpose,
    if (category != null) 'category': category,
    if (amount != null) 'amount': amount,
    if (date != null) 'date': date!.toIso8601String(),
    if (status != null) 'status': status,
    if (type != null) 'type': type,
  };
}

class PettyCashPage {
  const PettyCashPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<PettyCashRecord> items;
  final int page;
  final int total;
  final bool hasMore;
}

String? _text(dynamic value) => value?.toString();
num? _number(dynamic value) => value is num ? value : num.tryParse('$value');
DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Ringkasan saldo kas yang dihitung dari transaksi yang sudah dimuat.
class PettyCashSummary {
  const PettyCashSummary({required this.income, required this.expense});

  factory PettyCashSummary.fromItems(List<PettyCashRecord> items) {
    num income = 0;
    num expense = 0;
    for (final item in items) {
      final amount = item.amount ?? 0;
      if (item.isIncome) {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return PettyCashSummary(income: income, expense: expense);
  }

  final num income;
  final num expense;

  num get balance => income - expense;

  /// Porsi kas yang sudah terpakai (0..1).
  double get usedRatio =>
      income <= 0 ? 0 : (expense / income).clamp(0, 1).toDouble();
}
