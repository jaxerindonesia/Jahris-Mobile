enum HolidayType { national, collectiveLeave }

class Holiday {
  const Holiday({required this.name, required this.date, required this.type});

  final String name;
  final DateTime date;
  final HolidayType type;

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    name: json['localName']?.toString() ?? json['name']?.toString() ?? '-',
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime(2000),
    type:
        json['type'] == 'collective_leave' ||
            json['holidayType'] == 'collective_leave'
        ? HolidayType.collectiveLeave
        : HolidayType.national,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'type': type == HolidayType.collectiveLeave
        ? 'collective_leave'
        : 'national',
  };
}
