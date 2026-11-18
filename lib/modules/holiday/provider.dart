import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import 'model.dart';
import 'service.dart';

final holidayServiceProvider = Provider<HolidayService>((ref) {
  if (Env.useMock) return const MockHolidayService();
  return ApiHolidayService(
    Dio(
      BaseOptions(
        baseUrl: Env.holidayApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    ),
  );
});

final holidayProvider = AsyncNotifierProvider<HolidayController, HolidayState>(
  HolidayController.new,
);

class HolidayState {
  const HolidayState({
    required this.displayedMonth,
    required this.holidaysByYear,
  });

  final DateTime displayedMonth;
  final Map<int, List<Holiday>> holidaysByYear;

  List<Holiday> get holidays {
    final result = holidaysByYear.values.expand((items) => items).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  List<Holiday> get displayedHolidays => holidays
      .where(
        (holiday) =>
            holiday.date.year == displayedMonth.year &&
            holiday.date.month == displayedMonth.month,
      )
      .toList();

  List<Holiday> get upcomingHolidays {
    final start = DateTime(displayedMonth.year, displayedMonth.month);
    return holidays
        .where((holiday) => !holiday.date.isBefore(start))
        .take(6)
        .toList();
  }

  HolidayState copyWith({
    DateTime? displayedMonth,
    Map<int, List<Holiday>>? holidaysByYear,
  }) => HolidayState(
    displayedMonth: displayedMonth ?? this.displayedMonth,
    holidaysByYear: holidaysByYear ?? this.holidaysByYear,
  );
}

class HolidayController extends AsyncNotifier<HolidayState> {
  @override
  Future<HolidayState> build() async {
    final now = DateTime.now();
    final displayedMonth = DateTime(now.year, now.month + 1);
    final years = {displayedMonth.year, displayedMonth.year + 1};
    final entries = await Future.wait(
      years.map((year) async {
        final holidays = await ref
            .read(holidayServiceProvider)
            .list(year: year);
        return MapEntry(year, holidays);
      }),
    );
    return HolidayState(
      displayedMonth: displayedMonth,
      holidaysByYear: Map.fromEntries(entries),
    );
  }

  Future<void> previousMonth() => _moveMonth(-1);

  Future<void> nextMonth() => _moveMonth(1);

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final years = current.holidaysByYear.keys.toSet();
    final entries = await Future.wait(
      years.map((year) async {
        final holidays = await ref
            .read(holidayServiceProvider)
            .list(year: year);
        return MapEntry(year, holidays);
      }),
    );
    state = AsyncData(
      current.copyWith(holidaysByYear: Map.fromEntries(entries)),
    );
  }

  Future<void> _moveMonth(int offset) async {
    final current = state.value;
    if (current == null) return;
    final target = DateTime(
      current.displayedMonth.year,
      current.displayedMonth.month + offset,
    );
    if (current.holidaysByYear.containsKey(target.year)) {
      state = AsyncData(current.copyWith(displayedMonth: target));
      return;
    }
    final holidays = await ref
        .read(holidayServiceProvider)
        .list(year: target.year);
    state = AsyncData(
      current.copyWith(
        displayedMonth: target,
        holidaysByYear: {...current.holidaysByYear, target.year: holidays},
      ),
    );
  }
}
