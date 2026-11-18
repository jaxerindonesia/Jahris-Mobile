import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/branch/model.dart';

void main() {
  test('Branch mem-parsing jadwal kerja dari respons API', () {
    final branch = Branch.fromJson({
      'id': 'branch-1',
      'name': 'Barat Shift',
      'code': 'BS',
      'address': null,
      'attendanceRadiusMeters': 100,
      'scheduleType': 'SHIFT',
      'customWorkingHoursEnabled': true,
      'officeStartTime': '09:00',
      'officeEndTime': '17:00',
      'workingSchedules': [
        {
          'id': 'schedule-mon',
          'branchId': 'branch-1',
          'dayOfWeek': 'MONDAY',
          'isWorkDay': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
        {
          'id': 'schedule-sat',
          'branchId': 'branch-1',
          'dayOfWeek': 'SATURDAY',
          'isWorkDay': false,
          'startTime': null,
          'endTime': null,
        },
      ],
    });

    expect(branch.scheduleType, 'SHIFT');
    expect(branch.customWorkingHoursEnabled, isTrue);
    expect(branch.workingSchedules, hasLength(2));
    expect(branch.workingSchedules.first.startTime, '09:00');
    expect(branch.workingSchedules.last.isWorkDay, isFalse);
    expect(branch.workingSchedules.last.startTime, isNull);
  });

  test('ShiftScheduleState mencocokkan tanggal dengan dayOfWeek API', () {
    final monday = DateTime(2026, 11, 2);
    final branch = Branch.fromJson({
      'id': 'branch-1',
      'name': 'Barat Shift',
      'code': 'BS',
      'workingSchedules': [
        {
          'id': 'schedule-mon',
          'branchId': 'branch-1',
          'dayOfWeek': 'MONDAY',
          'isWorkDay': true,
          'startTime': '09:00',
          'endTime': '17:00',
        },
      ],
    });
    final state = ShiftScheduleState(
      branch: branch,
      weekStart: monday,
      selectedDate: monday,
    );

    expect(state.scheduleFor(monday)?.dayOfWeek, 'MONDAY');
    expect(state.scheduleFor(monday.add(const Duration(days: 1))), isNull);
  });
}
