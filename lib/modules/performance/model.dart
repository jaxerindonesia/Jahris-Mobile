class PerformanceRecord {
  const PerformanceRecord({
    this.id,
    this.employeeName,
    this.period,
    this.score,
    this.status,
  });

  final String? id;
  final String? employeeName;
  final String? period;
  final num? score;
  final String? status;

  // Terverifikasi dari kontrak halaman /performances pada 21 Oktober 2026.
  factory PerformanceRecord.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] ?? json['user'];
    return PerformanceRecord(
      id: _text(json['id'] ?? json['_id']),
      employeeName: _text(
        json['employeeName'] ??
            json['employee_name'] ??
            (employee is Map<String, dynamic>
                ? employee['name'] ?? employee['fullName']
                : employee),
      ),
      period: _text(json['period'] ?? json['month'] ?? json['year']),
      score: _number(
        json['totalScore'] ?? json['score'] ?? json['value'] ?? json['rating'],
      ),
      status: _text(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeName != null) 'employeeName': employeeName,
    if (period != null) 'period': period,
    if (score != null) 'score': score,
    if (status != null) 'status': status,
  };
}

class PerformancePage {
  const PerformancePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<PerformanceRecord> items;
  final int page;
  final int total;
  final bool hasMore;
}

String? _text(dynamic value) => value?.toString();
num? _number(dynamic value) => value is num ? value : num.tryParse('$value');
