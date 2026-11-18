class ReimburseSummary {
  const ReimburseSummary({
    required this.submitted,
    required this.approved,
    required this.pending,
  });
  final int submitted;
  final int approved;
  final int pending;

  // TODO-API: verifikasi nama agregat dari endpoint ringkasan web.
  factory ReimburseSummary.fromJson(Map<String, dynamic> json) =>
      ReimburseSummary(
        submitted: (json['submitted'] as num?)?.toInt() ?? 0,
        approved: (json['approved'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
      );
}

class Reimbursement {
  const Reimbursement({
    required this.id,
    required this.employeeName,
    required this.category,
    required this.amount,
    required this.date,
    required this.status,
    required this.description,
    this.receiptPath,
    this.approvalNote,
  });
  final String id;
  final String employeeName;
  final String category;
  final int amount;
  final DateTime date;
  final String status;
  final String description;
  final String? receiptPath;
  final String? approvalNote;

  // Terverifikasi dari GET /reimbursements pada 21 Oktober 2026.
  factory Reimbursement.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return Reimbursement(
      id: json['id']?.toString() ?? '',
      employeeName: user is Map<String, dynamic>
          ? user['name'] as String? ?? '-'
          : '-',
      category: json['category'] as String? ?? 'Lainnya',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Menunggu',
      description: json['description'] as String? ?? '-',
      receiptPath: json['receiptUrl'] as String?,
      approvalNote: json['approvalNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeName': employeeName,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status,
    'description': description,
    'receiptPath': receiptPath,
    'approvalNote': approvalNote,
  };

  Reimbursement copyWith({String? status, String? approvalNote}) =>
      Reimbursement(
        id: id,
        employeeName: employeeName,
        category: category,
        amount: amount,
        date: date,
        status: status ?? this.status,
        description: description,
        receiptPath: receiptPath,
        approvalNote: approvalNote ?? this.approvalNote,
      );
}

class ReimbursePage {
  const ReimbursePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<Reimbursement> items;
  final int page;
  final int total;
  final bool hasMore;
}

class ReimburseState {
  const ReimburseState({
    required this.summary,
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.filter = 'Semua',
    this.isSubmitting = false,
    this.message,
  });
  final ReimburseSummary summary;
  final List<Reimbursement> items;
  final int page;
  final int total;
  final bool hasMore;
  final String filter;
  final bool isSubmitting;
  final String? message;

  ReimburseState copyWith({
    ReimburseSummary? summary,
    List<Reimbursement>? items,
    int? page,
    int? total,
    bool? hasMore,
    String? filter,
    bool? isSubmitting,
    String? message,
    bool clearMessage = false,
  }) => ReimburseState(
    summary: summary ?? this.summary,
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    filter: filter ?? this.filter,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    message: clearMessage ? null : message ?? this.message,
  );
}
