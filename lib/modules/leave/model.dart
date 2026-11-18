class LeaveBalance {
  const LeaveBalance({
    required this.total,
    required this.used,
    required this.remaining,
  });

  final int total;
  final int used;
  final int remaining;

  // TODO-API: endpoint dan field saldo cuti belum terverifikasi.
  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
    total: (json['total'] as num?)?.toInt() ?? 0,
    used: (json['used'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'used': used,
    'remaining': remaining,
  };
}

class SubmissionType {
  const SubmissionType({required this.id, required this.name});

  final String id;
  final String name;

  // TODO-API: verifikasi field nama/label dari /submission-types.
  factory SubmissionType.fromJson(Map<String, dynamic> json) => SubmissionType(
    id: json['id']?.toString() ?? '',
    name: (json['name'] ?? json['label'] ?? json['title'])?.toString() ?? '-',
  );
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.attachmentName,
    this.approvalNote,
    this.department,
    this.durationLabel,
    this.reviewedBy,
  });

  final String id;
  final String employeeName;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final DateTime submittedAt;
  final String? attachmentName;
  final String? approvalNote;
  final String? department;
  final String? durationLabel;
  final String? reviewedBy;

  // Terverifikasi dari GET /submissions pada 21 Oktober 2026.
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final submissionType = json['submissionType'];
    final decisions = json['approvalDecisions'];
    final lastDecision = decisions is List && decisions.isNotEmpty
        ? decisions.last
        : null;
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      employeeName: user is Map<String, dynamic>
          ? user['name'] as String? ?? '-'
          : '-',
      type: submissionType is Map<String, dynamic>
          ? submissionType['name'] as String? ?? 'Pengajuan'
          : 'Pengajuan',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      reason: json['reason'] as String? ?? '-',
      status: json['status'] as String? ?? 'Menunggu',
      submittedAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      attachmentName: json['proofUrl'] as String?,
      approvalNote: lastDecision is Map<String, dynamic>
          ? lastDecision['reason'] as String?
          : null,
      department: json['department'] as String?,
      durationLabel: json['durationLabel'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeName': employeeName,
    'type': type,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'reason': reason,
    'status': status,
    'submittedAt': submittedAt.toIso8601String(),
    'attachmentName': attachmentName,
    'approvalNote': approvalNote,
    'department': department,
    'durationLabel': durationLabel,
    'reviewedBy': reviewedBy,
  };

  LeaveRequest copyWith({String? status, String? approvalNote}) => LeaveRequest(
    id: id,
    employeeName: employeeName,
    type: type,
    startDate: startDate,
    endDate: endDate,
    reason: reason,
    status: status ?? this.status,
    submittedAt: submittedAt,
    attachmentName: attachmentName,
    approvalNote: approvalNote ?? this.approvalNote,
    department: department,
    durationLabel: durationLabel,
    reviewedBy: reviewedBy,
  );
}

class LeavePage {
  const LeavePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<LeaveRequest> items;
  final int page;
  final int total;
  final bool hasMore;
}

class LeaveState {
  const LeaveState({
    required this.balance,
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.statusFilter = 'Semua',
    this.isSubmitting = false,
    this.message,
  });
  final LeaveBalance balance;
  final List<LeaveRequest> items;
  final int page;
  final int total;
  final bool hasMore;
  final String statusFilter;
  final bool isSubmitting;
  final String? message;

  LeaveState copyWith({
    LeaveBalance? balance,
    List<LeaveRequest>? items,
    int? page,
    int? total,
    bool? hasMore,
    String? statusFilter,
    bool? isSubmitting,
    String? message,
    bool clearMessage = false,
  }) => LeaveState(
    balance: balance ?? this.balance,
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    statusFilter: statusFilter ?? this.statusFilter,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    message: clearMessage ? null : message ?? this.message,
  );
}
