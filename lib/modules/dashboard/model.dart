class DashboardStat {
  const DashboardStat({
    required this.key,
    required this.label,
    required this.value,
    required this.description,
  });

  final String key;
  final String label;
  final String value;
  final String description;

  factory DashboardStat.fromJson(Map<String, dynamic> json) => DashboardStat(
    key: json['icon'] as String? ?? json['key'] as String? ?? '',
    label: json['title'] as String? ?? json['label'] as String? ?? '',
    value: json['value']?.toString() ?? '0',
    description: json['sub'] as String? ?? json['description'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'value': value,
    'description': description,
  };
}

class RecentSubmission {
  const RecentSubmission({
    required this.id,
    required this.employeeName,
    required this.type,
    required this.status,
    required this.submittedAt,
    this.department,
    this.detail,
  });

  final String id;
  final String employeeName;
  final String type;
  final String status;
  final DateTime submittedAt;
  final String? department;
  final String? detail;

  factory RecentSubmission.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final typeValue = json['submissionType'];
    return RecentSubmission(
      id: json['id']?.toString() ?? '',
      employeeName: user is Map<String, dynamic>
          ? user['name'] as String? ?? '-'
          : json['employeeName'] as String? ?? '-',
      type: typeValue is Map<String, dynamic>
          ? typeValue['name'] as String? ?? 'Pengajuan'
          : json['type'] as String? ?? 'Pengajuan',
      status: json['status'] as String? ?? 'Menunggu',
      submittedAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['submittedAt']) as String? ?? '',
          ) ??
          DateTime.now(),
      department: json['department'] as String?,
      detail: json['detail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeName': employeeName,
    'type': type,
    'status': status,
    'submittedAt': submittedAt.toIso8601String(),
    'department': department,
    'detail': detail,
  };
}

class DashboardSummary {
  const DashboardSummary({
    required this.stats,
    required this.recentSubmissions,
  });

  final List<DashboardStat> stats;
  final List<RecentSubmission> recentSubmissions;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final stats = json['summaryCards'] as List<dynamic>? ?? const [];
    final submissions = json['recentSubmissions'] as List<dynamic>? ?? const [];
    return DashboardSummary(
      stats: stats
          .whereType<Map<String, dynamic>>()
          .map(DashboardStat.fromJson)
          .toList(growable: false),
      recentSubmissions: submissions
          .whereType<Map<String, dynamic>>()
          .map(RecentSubmission.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'stats': stats.map((item) => item.toJson()).toList(),
    'recentSubmissions': recentSubmissions
        .map((item) => item.toJson())
        .toList(),
  };
}
