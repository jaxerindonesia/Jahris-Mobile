class PayrollSummary {
  const PayrollSummary({
    required this.paid,
    required this.pending,
    required this.total,
    required this.year,
  });
  final int paid;
  final int pending;
  final int total;
  final int year;

  factory PayrollSummary.fromJson(Map<String, dynamic> json) => PayrollSummary(
    paid: (json['paid'] as num?)?.toInt() ?? 0,
    pending: (json['pending'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
  );
}

class PayrollSlip {
  const PayrollSlip({
    required this.id,
    required this.employeeName,
    required this.period,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.status,
    required this.paidAt,
    this.periodDate,
    this.lines = const [],
  });
  final String id;
  final String employeeName;
  final String period;
  final int gross;
  final int deductions;
  final int net;
  final String status;
  final DateTime paidAt;

  /// Bulan periode gaji (fallback ke tanggal bayar).
  final DateTime? periodDate;

  /// Rincian pendapatan dan potongan.
  final List<PayrollLine> lines;

  DateTime get periodMonth => periodDate ?? paidAt;
  List<PayrollLine> get earnings =>
      lines.where((line) => !line.isDeduction).toList();
  List<PayrollLine> get deductionLines =>
      lines.where((line) => line.isDeduction).toList();

  // Terverifikasi dari kontrak halaman /payrolls.
  factory PayrollSlip.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final start = json['periodStartDate'];
    final end = json['periodEndDate'];
    final month = json['month'];
    final year = json['year'];
    return PayrollSlip(
      id: json['id']?.toString() ?? '',
      employeeName: user is Map<String, dynamic>
          ? user['name'] as String? ?? '-'
          : '-',
      period: start != null && end != null
          ? '$start s/d $end'
          : month != null && year != null
          ? '$month/$year'
          : '-',
      gross:
          ((json['basicSalary'] as num?)?.toInt() ?? 0) +
          ((json['allowances'] as num?)?.toInt() ?? 0),
      deductions: (json['deductions'] as num?)?.toInt() ?? 0,
      net: (json['totalSalary'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Pending',
      paidAt:
          DateTime.tryParse(json['paidAt'] as String? ?? '') ?? DateTime.now(),
      periodDate: _periodDate(month, year, end),
      lines: _lines(json),
    );
  }
}

class PayrollComponent {
  const PayrollComponent({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.active,
  });
  final String id;
  final String name;
  final String type;
  final int amount;
  final bool active;

  factory PayrollComponent.fromJson(Map<String, dynamic> json) =>
      PayrollComponent(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '-',
        type: json['type'] as String? ?? 'Tunjangan',
        amount: (json['defaultValue'] as num?)?.toInt() ?? 0,
        active: json['isActive'] as bool? ?? true,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'defaultValue': amount,
    'isActive': active,
  };
}

class PayrollPage {
  const PayrollPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<PayrollSlip> items;
  final int page;
  final int total;
  final bool hasMore;
}

class PayrollState {
  const PayrollState({
    required this.summary,
    required this.slips,
    required this.components,
    required this.page,
    required this.total,
    required this.hasMore,
    this.message,
    this.isDownloading = false,
  });
  final PayrollSummary summary;
  final List<PayrollSlip> slips;
  final List<PayrollComponent> components;
  final int page;
  final int total;
  final bool hasMore;
  final String? message;
  final bool isDownloading;

  PayrollState copyWith({
    PayrollSummary? summary,
    List<PayrollSlip>? slips,
    List<PayrollComponent>? components,
    int? page,
    int? total,
    bool? hasMore,
    String? message,
    bool clearMessage = false,
    bool? isDownloading,
  }) => PayrollState(
    summary: summary ?? this.summary,
    slips: slips ?? this.slips,
    components: components ?? this.components,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    message: clearMessage ? null : message ?? this.message,
    isDownloading: isDownloading ?? this.isDownloading,
  );
}

/// Satu baris rincian slip gaji.
class PayrollLine {
  const PayrollLine({
    required this.name,
    required this.amount,
    this.isDeduction = false,
  });

  final String name;
  final int amount;
  final bool isDeduction;

  factory PayrollLine.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['category'] ?? '').toString();
    return PayrollLine(
      name: (json['name'] ?? json['label'] ?? '-').toString(),
      amount: _int(json['amount'] ?? json['value'] ?? json['nominal']),
      isDeduction:
          json['isDeduction'] == true ||
          type.toLowerCase().contains('potongan') ||
          type.toLowerCase().contains('deduction'),
    );
  }
}

int _int(dynamic value) =>
    value is num ? value.toInt() : num.tryParse('$value')?.toInt() ?? 0;

DateTime? _periodDate(dynamic month, dynamic year, dynamic end) {
  final m = month is num ? month.toInt() : int.tryParse('$month');
  final y = year is num ? year.toInt() : int.tryParse('$year');
  if (m != null && y != null && m >= 1 && m <= 12) return DateTime(y, m);
  return end is String ? DateTime.tryParse(end) : null;
}

List<PayrollLine> _lines(Map<String, dynamic> json) {
  final raw = json['items'] ?? json['details'] ?? json['components'];
  if (raw is List && raw.isNotEmpty) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PayrollLine.fromJson)
        .toList();
  }
  final basic = _int(json['basicSalary']);
  final allowances = _int(json['allowances']);
  final overtime = _int(json['overtimePay'] ?? json['overtime']);
  final deductions = _int(json['deductions']);
  return [
    if (basic > 0) PayrollLine(name: 'Gaji Pokok', amount: basic),
    if (allowances > 0) PayrollLine(name: 'Tunjangan', amount: allowances),
    if (overtime > 0) PayrollLine(name: 'Lembur', amount: overtime),
    if (deductions > 0)
      PayrollLine(name: 'Potongan', amount: deductions, isDeduction: true),
  ];
}
