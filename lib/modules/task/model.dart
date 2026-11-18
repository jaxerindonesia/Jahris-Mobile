class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.comments = const [],
    this.project,
    this.subtasks = const [],
    this.attachments = 0,
  });

  final String id;
  final String title;
  final String description;
  final String assignee;
  final DateTime dueDate;
  final String priority;
  final String status;
  final List<String> comments;
  final String? project;
  final List<TaskSubtask> subtasks;
  final int attachments;

  bool get isCompleted {
    final normalized = status.toLowerCase();
    return const [
      'selesai',
      'done',
      'completed',
      'complete',
    ].contains(normalized.trim());
  }

  int get completedSubtaskCount => subtasks.where((item) => item.done).length;

  bool matchesFilter(String filter) {
    if (filter == 'Semua') return true;
    if (filter == 'Selesai') return isCompleted;
    if (filter == 'Berjalan') return !isCompleted;
    return status.toLowerCase() == filter.toLowerCase();
  }

  // Terverifikasi dari board /task-managements/lists.
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final members = json['members'];
    final assigneeNames = members is List
        ? members
              .whereType<Map<String, dynamic>>()
              .map((item) {
                final user = item['user'];
                return user is Map<String, dynamic>
                    ? user['name']?.toString()
                    : item['name']?.toString();
              })
              .whereType<String>()
              .join(', ')
        : '';
    final project = json['project'];
    final subtaskRaws = json['subtasks'] ?? json['checklist'];
    final attachmentRaws = json['attachments'];
    return TaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String? ?? '-',
      assignee: assigneeNames.isNotEmpty
          ? assigneeNames
          : json['assignee'] as String? ?? '-',
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      priority: json['priority'] as String? ?? 'Sedang',
      status: json['status'] as String? ?? 'Berjalan',
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      project: project is Map<String, dynamic>
          ? (project['name'] ?? project['title'])?.toString()
          : project is String && project.isNotEmpty
          ? project
          : null,
      subtasks: subtaskRaws is List
          ? [
              for (final raw in subtaskRaws.whereType<Map<String, dynamic>>())
                TaskSubtask(
                  title: (raw['title'] ?? raw['name'])?.toString() ?? '-',
                  done: raw['done'] == true || raw['isDone'] == true,
                ),
            ]
          : const [],
      attachments: attachmentRaws is List
          ? attachmentRaws.length
          : attachmentRaws is num
          ? attachmentRaws.toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'assignee': assignee,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority,
    'status': status,
    'comments': comments,
    'project': project,
    'subtasks': [
      for (final subtask in subtasks)
        {'title': subtask.title, 'done': subtask.done},
    ],
    'attachments': attachments,
  };

  TaskItem copyWith({
    String? status,
    List<String>? comments,
    List<TaskSubtask>? subtasks,
  }) => TaskItem(
    id: id,
    title: title,
    description: description,
    assignee: assignee,
    dueDate: dueDate,
    priority: priority,
    status: status ?? this.status,
    comments: comments ?? this.comments,
    project: project,
    subtasks: subtasks ?? this.subtasks,
    attachments: attachments,
  );
}

class TaskSubtask {
  const TaskSubtask({required this.title, this.done = false});

  final String title;
  final bool done;
}

class TaskPage {
  const TaskPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.allItems,
  });
  final List<TaskItem> items;
  final int page;
  final int total;
  final bool hasMore;
  final List<TaskItem>? allItems;
}

class TaskState {
  const TaskState({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.filter = 'Semua',
    this.message,
    this.allItems,
    this.selectedDate,
  });
  final List<TaskItem> items;
  final int page;
  final int total;
  final bool hasMore;
  final String filter;
  final String? message;
  final List<TaskItem>? allItems;

  /// Tanggal yang dipilih di strip minggu. `null` berarti semua tanggal.
  final DateTime? selectedDate;

  bool get hasDateFilter => selectedDate != null;

  bool get isTodaySelected {
    final date = selectedDate;
    return date != null && DateUtilsX.isSameDay(date, DateTime.now());
  }

  /// Tugas pada daftar (sesuai filter status dan tanggal).
  List<TaskItem> get visibleItems {
    final date = selectedDate;
    if (date == null) return items;
    return items
        .where((item) => DateUtilsX.isSameDay(item.dueDate.toLocal(), date))
        .toList();
  }

  /// Ringkasan progres: tanggal terpilih, atau keseluruhan bila tanpa filter.
  List<TaskItem> get progressItems {
    final date = selectedDate;
    if (date == null) return overviewItems;
    return overviewItems
        .where((item) => DateUtilsX.isSameDay(item.dueDate.toLocal(), date))
        .toList();
  }

  int get progressCompleted =>
      progressItems.where((item) => item.isCompleted).length;
  int get progressTotal =>
      selectedDate == null ? overviewTotal : progressItems.length;

  List<TaskItem> get overviewItems => allItems ?? items;
  int get completedCount =>
      overviewItems.where((item) => item.isCompleted).length;
  int get pendingCount =>
      overviewItems.where((item) => !item.isCompleted).length;
  int get overviewTotal => allItems?.length ?? total;

  bool hasReminderOn(DateTime date) => overviewItems.any(
    (item) =>
        !item.isCompleted &&
        item.dueDate.year == date.year &&
        item.dueDate.month == date.month &&
        item.dueDate.day == date.day,
  );

  TaskState copyWith({
    List<TaskItem>? items,
    int? page,
    int? total,
    bool? hasMore,
    String? filter,
    String? message,
    bool clearMessage = false,
    List<TaskItem>? allItems,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) => TaskState(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    filter: filter ?? this.filter,
    message: clearMessage ? null : message ?? this.message,
    allItems: allItems ?? this.allItems,
    selectedDate: clearSelectedDate ? null : selectedDate ?? this.selectedDate,
  );
}

abstract final class DateUtilsX {
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
