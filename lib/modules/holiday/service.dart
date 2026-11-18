import 'package:dio/dio.dart';

import 'model.dart';

abstract interface class HolidayService {
  Future<List<Holiday>> list({required int year});
}

class ApiHolidayService implements HolidayService {
  const ApiHolidayService(this._dio);

  final Dio _dio;

  @override
  Future<List<Holiday>> list({required int year}) async {
    final response = await _dio.get<List<dynamic>>('/PublicHolidays/$year/ID');
    final data = response.data ?? const [];
    final holidays = data
        .whereType<Map<String, dynamic>>()
        .map(Holiday.fromJson)
        .toList();
    holidays.sort((a, b) => a.date.compareTo(b.date));
    return holidays;
  }
}

class MockHolidayService implements HolidayService {
  const MockHolidayService();

  @override
  Future<List<Holiday>> list({required int year}) async {
    final holidays = [
      Holiday(
        name: 'Hari Raya Natal',
        date: DateTime(2026, 12, 25),
        type: HolidayType.national,
      ),
      Holiday(
        name: 'Cuti Bersama Natal',
        date: DateTime(2026, 12, 24),
        type: HolidayType.collectiveLeave,
      ),
      Holiday(
        name: 'Tahun Baru 2027',
        date: DateTime(2027, 1, 1),
        type: HolidayType.national,
      ),
      Holiday(
        name: 'Tahun Baru Imlek',
        date: DateTime(2027, 2, 6),
        type: HolidayType.national,
      ),
    ];
    return holidays.where((holiday) => holiday.date.year == year).toList();
  }
}
