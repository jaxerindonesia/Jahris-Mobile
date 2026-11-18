import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import 'model.dart';

abstract interface class TaskService {
  Future<TaskPage> list({int page = 1, int limit = 10, String? status});
  Future<TaskItem> detail(String id);
  Future<TaskItem> update(String id, {String? status, String? comment});
}

class ApiTaskService implements TaskService {
  ApiTaskService(this._dio);
  final Dio _dio;
  final Map<String, TaskItem> _cache = {};
  final Map<String, String> _listIds = {};

  @override
  Future<TaskPage> list({int page = 1, int limit = 10, String? status}) async {
    final departmentsResponse = await _dio.get<dynamic>(
      ApiEndpoints.taskDepartments,
    );
    final departments = apiList(
      departmentsResponse.data,
      collectionKeys: const ['departments'],
    );
    final all = <TaskItem>[];
    for (final department in departments) {
      final departmentId = department['id']?.toString();
      if (departmentId == null || departmentId.isEmpty) continue;
      final boardResponse = await _dio.get<dynamic>(
        ApiEndpoints.taskLists,
        queryParameters: {'departmentId': departmentId},
      );
      final board = apiObject(boardResponse.data);
      final rawLists = board['lists'];
      if (rawLists is! List) continue;
      for (final rawList in rawLists.whereType<Map<String, dynamic>>()) {
        final listName = rawList['name']?.toString() ?? 'Berjalan';
        final listId = rawList['id']?.toString() ?? '';
        _listIds[listName.toLowerCase()] = listId;
        final tasks = rawList['tasks'];
        if (tasks is! List) continue;
        for (final task in tasks.whereType<Map<String, dynamic>>()) {
          final item = TaskItem.fromJson({...task, 'status': listName});
          _cache[item.id] = item;
          all.add(item);
        }
      }
    }
    final filtered = status == null || status == 'Semua'
        ? all
        : all.where((item) => item.matchesFilter(status)).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return TaskPage(
      items: start >= filtered.length ? const [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
      allItems: all,
    );
  }

  @override
  Future<TaskItem> detail(String id) async {
    if (_cache[id] case final cached?) return cached;
    await list(limit: 999999);
    final item = _cache[id];
    if (item == null) throw StateError('Tugas tidak ditemukan.');
    return item;
  }

  @override
  Future<TaskItem> update(String id, {String? status, String? comment}) async {
    final current = await detail(id);
    final data = <String, dynamic>{};
    if (status != null) {
      final target = _listIds.entries.where((entry) {
        final key = entry.key;
        return status == 'Selesai'
            ? key.contains('done') || key.contains('selesai')
            : !key.contains('done') && !key.contains('selesai');
      }).firstOrNull;
      if (target != null) data['listId'] = target.value;
    }
    if (comment != null) {
      throw UnsupportedError(
        'API web belum menyediakan endpoint komentar tugas.',
      );
    }
    await _dio.put<Map<String, dynamic>>(ApiEndpoints.task(id), data: data);
    final updated = current.copyWith(status: status);
    _cache[id] = updated;
    return updated;
  }
}

class MockTaskService implements TaskService {
  MockTaskService();

  static DateTime _dueThisWeek(int weekday, int hour, [int minute = 0]) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day - now.weekday + weekday,
      hour,
      minute,
    );
  }

  final List<TaskItem> _items = [
    TaskItem(
      id: 'task-1',
      title: 'Review desain halaman Kehadiran',
      description:
          'Cek konsistensi komponen kartu, warna status, dan alur '
          'check-in/out di halaman Kehadiran sebelum handoff ke developer.',
      assignee: 'Rina Pratama',
      dueDate: _dueThisWeek(DateTime.monday, 10),
      priority: 'Tinggi',
      status: 'Berjalan',
      project: 'Jahris Mobile',
      attachments: 2,
      subtasks: const [
        TaskSubtask(title: 'Cek warna chip status', done: true),
        TaskSubtask(title: 'Review state kosong riwayat', done: true),
        TaskSubtask(title: 'Validasi ukuran tap area'),
        TaskSubtask(title: 'Tulis catatan handoff'),
      ],
      comments: const ['Struktur halaman sudah diperiksa.'],
    ),
    TaskItem(
      id: 'task-2',
      title: 'Meeting sprint planning',
      description: 'Susun prioritas pengembangan untuk sprint berikutnya.',
      assignee: 'Tim Produk',
      dueDate: _dueThisWeek(DateTime.tuesday, 13),
      priority: 'Sedang',
      status: 'Berjalan',
    ),
    TaskItem(
      id: 'task-3',
      title: 'Update dokumentasi API cuti',
      description: 'Perbarui kontrak endpoint dan contoh payload cuti.',
      assignee: 'Backend',
      dueDate: _dueThisWeek(DateTime.wednesday, 15, 30),
      priority: 'Rendah',
      status: 'Berjalan',
    ),
    TaskItem(
      id: 'task-4',
      title: 'Siapkan agenda onboarding',
      description: 'Lengkapi agenda karyawan baru minggu depan.',
      assignee: 'HR',
      dueDate: _dueThisWeek(DateTime.friday, 16),
      priority: 'Sedang',
      status: 'Berjalan',
    ),
    TaskItem(
      id: 'task-5',
      title: 'Kirim laporan mingguan',
      description: 'Kirim laporan operasional kepada manajemen.',
      assignee: 'Operasional',
      dueDate: _dueThisWeek(DateTime.monday, 9),
      priority: 'Rendah',
      status: 'Selesai',
    ),
    TaskItem(
      id: 'task-6',
      title: 'Balas email klien PT Maju',
      description: 'Konfirmasi kebutuhan implementasi kepada klien.',
      assignee: 'Sales',
      dueDate: _dueThisWeek(DateTime.thursday, 8, 30),
      priority: 'Sedang',
      status: 'Selesai',
    ),
    TaskItem(
      id: 'task-7',
      title: 'Verifikasi reimburse Oktober',
      description: 'Pastikan seluruh bukti reimburse sudah lengkap.',
      assignee: 'Finance',
      dueDate: _dueThisWeek(DateTime.saturday, 8),
      priority: 'Tinggi',
      status: 'Selesai',
    ),
  ];

  @override
  Future<TaskPage> list({int page = 1, int limit = 10, String? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final filtered = status == null || status == 'Semua'
        ? _items
        : _items.where((item) => item.matchesFilter(status)).toList();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, filtered.length);
    return TaskPage(
      items: start >= filtered.length ? [] : filtered.sublist(start, end),
      page: page,
      total: filtered.length,
      hasMore: end < filtered.length,
      allItems: List.unmodifiable(_items),
    );
  }

  @override
  Future<TaskItem> detail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<TaskItem> update(String id, {String? status, String? comment}) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Tugas tidak ditemukan.');
    final current = _items[index];
    final updated = current.copyWith(
      status: status,
      comments: comment == null || comment.trim().isEmpty
          ? current.comments
          : [...current.comments, comment.trim()],
    );
    _items[index] = updated;
    return updated;
  }
}
