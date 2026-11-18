class OvertimeRecord {
  const OvertimeRecord({
    this.id,
    this.employeeName,
    this.date,
    this.hours,
    this.status,
    this.startAt,
    this.endAt,
    this.note,
    this.estimatedPay,
  });

  final String? id;
  final String? employeeName;
  final DateTime? date;
  final double? hours;
  final String? status;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? note;
  final double? estimatedPay;

  // Terverifikasi dari GET /overtimes pada 21 Oktober 2026.
  factory OvertimeRecord.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] ?? json['user'];
    return OvertimeRecord(
      id: _text(json['id'] ?? json['_id']),
      employeeName: _text(
        json['employeeName'] ??
            json['employee_name'] ??
            (employee is Map<String, dynamic>
                ? employee['name'] ?? employee['fullName']
                : employee),
      ),
      date: _date(json['date'] ?? json['overtimeDate'] ?? json['createdAt']),
      hours: json['overtimeMinutes'] is num
          ? (json['overtimeMinutes'] as num).toDouble() / 60
          : _number(json['hours'] ?? json['duration'] ?? json['totalHours']),
      status: _text(json['status']),
      startAt: _date(
        json['startAt'] ??
            json['start_at'] ??
            json['startTime'] ??
            json['start_time'] ??
            json['start'] ??
            json['startedAt'],
      ),
      endAt: _date(
        json['endAt'] ??
            json['end_at'] ??
            json['endTime'] ??
            json['end_time'] ??
            json['end'] ??
            json['endedAt'],
      ),
      note: _text(
        json['note'] ??
            json['notes'] ??
            json['reason'] ??
            json['description'] ??
            json['remarks'],
      ),
      estimatedPay: _number(
        json['estimatedPay'] ??
            json['estimated_pay'] ??
            json['estimatedAmount'] ??
            json['amount'] ??
            json['pay'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeName != null) 'employeeName': employeeName,
    if (date != null) 'date': date!.toIso8601String(),
    if (hours != null) 'hours': hours,
    if (status != null) 'status': status,
    if (startAt != null) 'startAt': startAt!.toIso8601String(),
    if (endAt != null) 'endAt': endAt!.toIso8601String(),
    if (note != null) 'note': note,
    if (estimatedPay != null) 'estimatedPay': estimatedPay,
  };
}

class OvertimePage {
  const OvertimePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  final List<OvertimeRecord> items;
  final int page;
  final int total;
  final bool hasMore;
}

String? _text(dynamic value) => value?.toString();
double? _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
