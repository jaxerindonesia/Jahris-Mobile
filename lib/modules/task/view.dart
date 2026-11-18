import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/task_theme.dart';
import '../../core/theme/task_detail_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import 'model.dart';
import 'provider.dart';

class TaskView extends ConsumerWidget {
  const TaskView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(taskProvider);
    final searchableItems = value.asData?.value.items ?? const <TaskItem>[];
    return ModuleScaffold(
      title: context.l10n.taskTitle,
      currentIndex: 2,
      showAppHeader: false,
      showPageHeading: false,
      backgroundGradient: TaskTheme.background,
      contentPadding: TaskTheme.pagePadding,
      floatingActionButton: SizedBox.square(
        dimension: 58,
        child: FloatingActionButton(
          tooltip: context.l10n.taskAdd,
          backgroundColor: TaskTheme.primary,
          foregroundColor: TaskTheme.white,
          shape: const CircleBorder(),
          elevation: 0,
          onPressed: () => _showNewTask(context),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TaskHeader(
            onSearch: () => showSearch<void>(
              context: context,
              delegate: _TaskSearchDelegate(
                searchableItems,
                label: context.l10n.taskSearch,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: value.when(
              loading: () => const ListLoading(),
              error: (_, _) => ListError(
                message: context.l10n.taskLoadError,
                onRetry: () => ref.invalidate(taskProvider),
              ),
              data: (data) => _TaskContent(data: data),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewTask(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? TaskTheme.sheetBarrier
          : AppColors.lightText.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(borderRadius: TaskTheme.sheetRadius),
      builder: (sheetContext) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark ? TaskTheme.sheetGradient : null,
          color: isDark ? null : AppColors.lightSurface,
          borderRadius: TaskTheme.sheetRadius,
          border: Border(
            top: BorderSide(
              color: isDark ? TaskTheme.sheetBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: _NewTaskSheet(
          onSaved: () {
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.taskSavedReady)),
            );
          },
        ),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.taskTitle,
              style: TaskTheme.heading.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: TaskTheme.date,
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: context.l10n.taskSearch,
        onPressed: onSearch,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? TaskTheme.surface
              : AppColors.lightSurface,
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.search_rounded, size: 20),
      ),
    ],
  );
}

class _TaskContent extends ConsumerWidget {
  const _TaskContent({required this.data});
  final TaskState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          _ProgressCard(data: data),
          const SizedBox(height: 18),
          _WeekStrip(data: data, onSelected: controller.selectDate),
          const SizedBox(height: 16),
          _TaskFilters(data: data, onSelected: controller.setFilter),
          const SizedBox(height: 16),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
          if (data.selectedDate case final date?) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.taskOnDate(
                      DateFormat(
                        'EEEE, d MMMM',
                        context.dateLocale,
                      ).format(date),
                    ),
                    style: TaskTheme.title.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => controller.selectDate(null),
                  child: Text(context.l10n.taskShowAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (data.visibleItems.isEmpty)
            GlassCard(
              child: Center(
                child: Text(switch (data.selectedDate) {
                  null => context.l10n.taskEmptyFilter,
                  _ when data.isTodaySelected => context.l10n.taskEmptyToday,
                  final date => context.l10n.taskEmptyDate(
                    DateFormat('EEEE, d MMMM', context.dateLocale).format(date),
                  ),
                }, textAlign: TextAlign.center),
              ),
            )
          else ...[
            for (final item in data.visibleItems) ...[
              _TaskCard(item: item),
              const SizedBox(height: 10),
            ],
            if (data.hasMore)
              TextButton(
                onPressed: controller.loadMore,
                child: Text(context.l10n.attLoadMore),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data});
  final TaskState data;

  @override
  Widget build(BuildContext context) {
    final total = data.progressTotal;
    final completed = data.progressCompleted;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final caption = switch (data.selectedDate) {
      null => context.l10n.taskProgressToday,
      _ when data.isTodaySelected => context.l10n.taskProgressToday,
      final date => context.l10n.taskProgressDate(
        DateFormat('EEEE, d MMM', context.dateLocale).format(date),
      ),
    };
    return Container(
      key: const ValueKey('task-progress'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: TaskTheme.progressGradient,
        borderRadius: TaskTheme.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(caption, style: TaskTheme.progressCaption),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? context.l10n.taskNone
                : context.l10n.taskProgressCount(completed, total),
            style: TaskTheme.progressTitle,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: TaskTheme.pillRadius,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: TaskTheme.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(TaskTheme.white),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Text('${(progress * 100).round()}%', style: TaskTheme.percent),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.data, required this.onSelected});
  final TaskState data;
  final ValueChanged<DateTime?> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(
      7,
      (index) => DateTime(monday.year, monday.month, monday.day + index),
    );
    return Row(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          Expanded(
            child: _DayCell(
              date: days[index],
              selected: DateUtils.isSameDay(
                days[index],
                data.selectedDate ?? today,
              ),
              hasReminder: data.hasReminderOn(days[index]),
              onTap: () => onSelected(days[index]),
            ),
          ),
          if (index < 6) const SizedBox(width: TaskTheme.dayGap),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.hasReminder,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final bool hasReminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label:
          '${DateFormat('EEEE, d MMMM yyyy', context.dateLocale).format(date)}'
          '${hasReminder ? context.l10n.taskHasPending : context.l10n.taskNoReminder}',
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: ValueKey('task-day-${DateFormat('yyyy-MM-dd').format(date)}'),
          height: TaskTheme.dayHeight,
          decoration: BoxDecoration(
            color: selected
                ? TaskTheme.primary
                : dark
                ? TaskTheme.surface
                : AppColors.lightSurface,
            borderRadius: TaskTheme.dayRadius,
            border: Border.all(
              color: selected
                  ? TaskTheme.primary
                  : dark
                  ? TaskTheme.border
                  : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'id_ID').format(date).substring(0, 3),
                style: TaskTheme.weekday.copyWith(
                  color: selected ? TaskTheme.white : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${date.day}',
                style: TaskTheme.day.copyWith(
                  color: selected
                      ? TaskTheme.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox.square(
                dimension: TaskTheme.reminderSize,
                child: hasReminder
                    ? DecoratedBox(
                        key: ValueKey(
                          'task-reminder-${DateFormat('yyyy-MM-dd').format(date)}',
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? TaskTheme.white : TaskTheme.muted,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({required this.data, required this.onSelected});
  final TaskState data;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final filters = [
      (context.l10n.taskFilterAll(data.overviewTotal), 'Semua'),
      (context.l10n.taskFilterPending(data.pendingCount), 'Berjalan'),
      (context.l10n.taskFilterDone(data.completedCount), 'Selesai'),
    ];
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? TaskTheme.surface : AppColors.lightSurface,
        borderRadius: TaskTheme.pillRadius,
        border: Border.all(
          color: dark ? TaskTheme.border : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          for (final filter in filters)
            Expanded(
              child: _FilterButton(
                label: filter.$1,
                selected: data.filter == filter.$2,
                onTap: () => onSelected(filter.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? TaskTheme.primary : AppColors.transparent,
    borderRadius: TaskTheme.pillRadius,
    child: InkWell(
      borderRadius: TaskTheme.pillRadius,
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TaskTheme.filter.copyWith(
            color: selected ? TaskTheme.white : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.item});
  final TaskItem item;

  Color get _priorityColor {
    final p = item.priority.toLowerCase();
    if (p.contains('tinggi') || p.contains('high')) return TaskTheme.high;
    if (p.contains('rendah') || p.contains('low')) return TaskTheme.low;
    return TaskTheme.medium;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final completed = item.isCompleted;
    return Material(
      color: dark ? TaskTheme.surface : AppColors.lightSurface,
      borderRadius: TaskTheme.cardRadius,
      child: InkWell(
        borderRadius: TaskTheme.cardRadius,
        onTap: () => context.push('/task/detail/${item.id}'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            borderRadius: TaskTheme.cardRadius,
            border: Border.all(
              color: dark ? TaskTheme.border : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                decoration: BoxDecoration(
                  color: completed ? AppColors.transparent : _priorityColor,
                  borderRadius: TaskTheme.pillRadius,
                ),
              ),
              IconButton(
                tooltip: completed
                    ? context.l10n.taskMarkUndone
                    : context.l10n.taskMarkDone,
                onPressed: () => ref
                    .read(taskProvider.notifier)
                    .updateTask(
                      item.id,
                      status: completed ? 'Berjalan' : 'Selesai',
                    ),
                icon: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: completed ? TaskTheme.low : TaskTheme.muted,
                  size: 23,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TaskTheme.title.copyWith(
                          color: completed
                              ? TaskTheme.muted
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: TaskTheme.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm', 'id_ID').format(item.dueDate),
                            style: TaskTheme.metadata,
                          ),
                          const SizedBox(width: 6),
                          const Text('·', style: TaskTheme.metadata),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.project ?? item.assignee,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TaskTheme.metadata,
                            ),
                          ),
                          if (item.subtasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 12,
                              color: TaskTheme.muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${item.completedSubtaskCount}/${item.subtasks.length}',
                              style: TaskTheme.metadata,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!completed) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor.withValues(alpha: 0.14),
                    borderRadius: TaskTheme.pillRadius,
                  ),
                  child: Text(
                    _taskLabel(context, item.priority),
                    style: TaskTheme.priority.copyWith(color: _priorityColor),
                  ),
                ),
              ] else
                const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSearchDelegate extends SearchDelegate<void> {
  _TaskSearchDelegate(this.items, {required String label})
    : super(searchFieldLabel: label);

  final List<TaskItem> items;

  // Materi 3 memaksa teks search bar berukuran 20;
  // kita samakan dengan hint pencarian ("Cari layanan...") = 15 regular.
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        centerTitle: true,
        titleTextStyle: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.75)
              : AppColors.lightMuted,
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: context.l10n.taskClearSearch,
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: context.l10n.attBack,
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final keyword = query.trim().toLowerCase();
    final results = keyword.isEmpty
        ? items
        : items
              .where(
                (item) =>
                    item.title.toLowerCase().contains(keyword) ||
                    item.assignee.toLowerCase().contains(keyword),
              )
              .toList();
    if (results.isEmpty) {
      return Center(child: Text(context.l10n.taskNotFound));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _TaskCard(item: results[index]),
    );
  }
}

class _NewTaskSheet extends StatefulWidget {
  const _NewTaskSheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  String _due = 'Hari ini';
  String _priority = 'Rendah';
  bool _reminder = true;
  DateTime? _pickedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: context.l10n.taskPickDue,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickedDate = picked;
      _due = 'Pilih';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _titleController.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.compact,
        0,
        AppSpacing.compact,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? TaskTheme.sheetHandle : AppColors.lightBorder,
                  borderRadius: TaskTheme.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              context.l10n.taskNew,
              textAlign: TextAlign.center,
              style: TaskTheme.sheetTitle.copyWith(
                color: isDark ? null : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetLabel(context.l10n.taskFieldTitle),
            _SheetField(
              controller: _titleController,
              hint: context.l10n.taskFieldTitleHint,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.compact),
            _SheetLabel(context.l10n.taskFieldNote),
            _SheetField(
              controller: _noteController,
              hint: context.l10n.taskFieldNoteHint,
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.compact),
            _SheetLabel(context.l10n.taskDue),
            Row(
              children: [
                for (final due in const [
                  'Hari ini',
                  'Besok',
                  'Minggu ini',
                ]) ...[
                  Expanded(
                    flex: _taskLabel(context, due).length + 6,
                    child: _SheetPill(
                      label: _taskLabel(context, due),
                      selected: _due == due,
                      onTap: () => setState(() => _due = due),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 12,
                  child: _SheetPill(
                    label: _pickedDate == null
                        ? context.l10n.taskDuePick
                        : AppFormatters.compactDate(_pickedDate!),
                    icon: Icons.calendar_today_outlined,
                    selected: _due == 'Pilih',
                    onTap: () => unawaited(_pickDate()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            _SheetLabel(context.l10n.taskPriority),
            Row(
              children: [
                for (final (index, priority) in const [
                  ('Rendah', TaskTheme.low),
                  ('Sedang', TaskTheme.medium),
                  ('Tinggi', TaskTheme.high),
                ].indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PriorityPill(
                      label: _taskLabel(context, priority.$1),
                      color: priority.$2,
                      selected: _priority == priority.$1,
                      onTap: () => setState(() => _priority = priority.$1),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            _ReminderTile(
              value: _reminder,
              onChanged: (value) => setState(() => _reminder = value),
            ),
            const SizedBox(height: AppSpacing.compact),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: TaskTheme.primary,
                  foregroundColor: TaskTheme.white,
                  disabledBackgroundColor: TaskTheme.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: TaskTheme.white.withValues(
                    alpha: 0.7,
                  ),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: canSave ? widget.onSaved : null,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(context.l10n.taskSave, style: TaskTheme.saveText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: TaskTheme.sheetLabel.copyWith(
          color: isDark ? null : AppColors.lightMuted,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: TaskTheme.fieldRadius,
      borderSide: BorderSide(
        color: isDark ? TaskTheme.fieldBorder : TaskTheme.lightFieldBorder,
      ),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: TaskTheme.fieldText.copyWith(
        color: isDark ? null : AppColors.lightText,
      ),
      cursorColor: TaskTheme.primary,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TaskTheme.fieldHint,
        filled: true,
        fillColor: isDark ? TaskTheme.fieldFill : TaskTheme.lightFieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.compact,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: TaskTheme.primary),
        ),
      ),
    );
  }
}

class _SheetPill extends StatelessWidget {
  const _SheetPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = selected
        ? TaskTheme.white
        : isDark
        ? null
        : AppColors.lightText;
    return InkWell(
      onTap: onTap,
      borderRadius: TaskTheme.pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected
              ? TaskTheme.primary
              : isDark
              ? TaskTheme.chipFill
              : TaskTheme.lightChipFill,
          borderRadius: TaskTheme.pillRadius,
          border: Border.all(
            color: selected
                ? TaskTheme.primary
                : isDark
                ? TaskTheme.chipBorder
                : TaskTheme.lightChipBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? TaskTheme.white : TaskTheme.reminderIcon,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TaskTheme.chipText.copyWith(
                  color: textColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: TaskTheme.priorityRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.16 : 0.08),
          borderRadius: TaskTheme.priorityRadius,
          border: Border.all(
            color: selected
                ? color
                : isDark
                ? TaskTheme.chipBorder
                : color.withValues(alpha: 0.18),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: TaskTheme.reminderSize,
              height: TaskTheme.reminderSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TaskTheme.chipText.copyWith(
                color: selected
                    ? color
                    : isDark
                    ? null
                    : AppColors.lightText,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? TaskTheme.reminderFill : TaskTheme.lightReminderFill,
        borderRadius: TaskTheme.fieldRadius,
        border: Border.all(
          color: isDark ? TaskTheme.chipBorder : TaskTheme.lightFieldBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark
                  ? TaskTheme.reminderIconFill
                  : TaskTheme.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 16,
              color: TaskTheme.reminderIcon,
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.taskRemind,
                  style: TaskTheme.reminderTitle.copyWith(
                    color: isDark ? null : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.taskRemindHint,
                  style: TaskTheme.reminderCaption,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: TaskTheme.white,
              activeTrackColor: TaskTheme.primary,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailView extends ConsumerStatefulWidget {
  const TaskDetailView({required this.id, super.key});
  final String id;

  @override
  ConsumerState<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends ConsumerState<TaskDetailView> {
  final _toggledSubtasks = <int>{};
  bool _isSaving = false;

  String _dueLabel(DateTime due) {
    final local = due.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final day = target == today
        ? context.l10n.taskDueToday
        : target == DateTime(today.year, today.month, today.day + 1)
        ? context.l10n.taskDueTomorrow
        : AppFormatters.compactDate(local);
    final hasTime = local.hour != 0 || local.minute != 0;
    return hasTime ? '$day, ${AppFormatters.clockTime(local)}' : day;
  }

  bool _isSubtaskChecked(TaskSubtask subtask, int index) =>
      subtask.done != _toggledSubtasks.contains(index);

  Future<void> _setStatus(TaskItem item, String status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    bool success = false;
    try {
      await ref.read(taskProvider.future);
      if (!mounted) return;
      success = await ref
          .read(taskProvider.notifier)
          .updateTask(item.id, status: status);
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? status == 'Selesai'
                    ? context.l10n.taskMarkedDone
                    : context.l10n.taskStatusUpdated
              : context.l10n.taskStatusFailed,
        ),
      ),
    );
  }

  void _showComments(TaskItem item) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: dark ? TaskDetailTheme.surface : AppColors.lightSurface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: _CommentsPanel(item: item, isDark: dark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(taskDetailProvider(widget.id));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final item = value.value;
    final foreground = dark ? TaskDetailTheme.white : AppColors.lightText;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark ? TaskDetailTheme.background : null,
          color: dark ? null : AppColors.lightBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: IconButton(
                        tooltip: context.l10n.attBack,
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: dark
                              ? TaskDetailTheme.controlSurface
                              : AppColors.lightSurface,
                          foregroundColor: foreground,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.taskDetail,
                        textAlign: TextAlign.center,
                        style: TaskDetailTheme.header.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 36,
                      child: item == null
                          ? const SizedBox.shrink()
                          : PopupMenuButton<String>(
                              tooltip: context.l10n.taskMenu,
                              enabled: !_isSaving,
                              padding: EdgeInsets.zero,
                              onSelected: (action) {
                                if (action == 'Komentar') {
                                  _showComments(item);
                                } else {
                                  _setStatus(item, action);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'Berjalan',
                                  child: Text(context.l10n.taskMarkInProgress),
                                ),
                                PopupMenuItem(
                                  value: 'Selesai',
                                  child: Text(context.l10n.taskMarkDoneTitle),
                                ),
                                PopupMenuItem(
                                  value: 'Komentar',
                                  child: Text(
                                    context.l10n.taskCommentsCount(
                                      item.comments.length,
                                    ),
                                  ),
                                ),
                              ],
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dark
                                      ? TaskDetailTheme.controlSurface
                                      : AppColors.lightSurface,
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 21,
                                  color: foreground,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: value.when(
                  loading: () => const ListLoading(itemCount: 2),
                  error: (_, _) => ListError(
                    message: context.l10n.taskDetailError,
                    onRetry: () =>
                        ref.invalidate(taskDetailProvider(widget.id)),
                  ),
                  data: (item) {
                    final checkedCount = item.subtasks.indexed
                        .where((entry) => _isSubtaskChecked(entry.$2, entry.$1))
                        .length;
                    return ListView(
                      key: const ValueKey('task-detail-content'),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _TintedChip(
                              label: context.l10n.taskPriorityLabel(
                                _taskLabel(context, item.priority),
                              ),
                              color: item.priority.toLowerCase() == 'tinggi'
                                  ? TaskDetailTheme.high
                                  : item.priority.toLowerCase() == 'rendah'
                                  ? TaskTheme.low
                                  : TaskTheme.medium,
                            ),
                            if (item.project case final project?)
                              _TintedChip(
                                label: project,
                                color: TaskDetailTheme.blueText,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: TaskDetailTheme.title.copyWith(
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _InfoPanel(
                          item: item,
                          isDark: dark,
                          dueLabel: _dueLabel(item.dueDate),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.taskDescription,
                          style: TaskDetailTheme.section.copyWith(
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: TaskDetailTheme.description.copyWith(
                            color: dark
                                ? TaskDetailTheme.descriptionColor
                                : AppColors.lightMuted,
                          ),
                        ),
                        if (item.subtasks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.taskSubtasks,
                                  style: TaskDetailTheme.section.copyWith(
                                    color: foreground,
                                  ),
                                ),
                              ),
                              Text(
                                context.l10n.taskSubtaskCount(
                                  checkedCount,
                                  item.subtasks.length,
                                ),
                                style: TaskDetailTheme.label,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: TaskDetailTheme.pillRadius,
                            child: LinearProgressIndicator(
                              key: const ValueKey('task-subtask-progress'),
                              value: checkedCount / item.subtasks.length,
                              minHeight: 6,
                              color: TaskDetailTheme.blue,
                              backgroundColor: dark
                                  ? TaskDetailTheme.track
                                  : AppColors.lightBorder,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final (index, subtask)
                              in item.subtasks.indexed) ...[
                            if (index > 0) const SizedBox(height: 8),
                            _SubtaskRow(
                              key: ValueKey('task-subtask-$index'),
                              subtask: subtask,
                              checked: _isSubtaskChecked(subtask, index),
                              onTap: () => setState(() {
                                _toggledSubtasks.contains(index)
                                    ? _toggledSubtasks.remove(index)
                                    : _toggledSubtasks.add(index);
                              }),
                            ),
                          ],
                        ],
                        if (item.attachments > 0) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 17,
                                color: TaskDetailTheme.muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.taskAttachments(item.attachments),
                                style: TaskDetailTheme.label,
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (item != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving || item.isCompleted
                          ? null
                          : () => _setStatus(item, 'Selesai'),
                      style: FilledButton.styleFrom(
                        backgroundColor: TaskDetailTheme.green,
                        foregroundColor: TaskDetailTheme.white,
                        disabledBackgroundColor: TaskDetailTheme.green
                            .withValues(alpha: 0.5),
                        disabledForegroundColor: TaskDetailTheme.white,
                        shape: const StadiumBorder(),
                      ),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TaskDetailTheme.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        item.isCompleted
                            ? context.l10n.taskDoneTitle
                            : context.l10n.taskMarkDoneTitle,
                        style: TaskDetailTheme.button,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.checked,
    required this.onTap,
    super.key,
  });
  final TaskSubtask subtask;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      checked: checked,
      label: subtask.title,
      button: true,
      child: Material(
        color: dark ? TaskDetailTheme.surface : AppColors.lightSurface,
        borderRadius: TaskDetailTheme.rowRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: TaskDetailTheme.rowRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: checked
                        ? TaskDetailTheme.checked
                        : AppColors.transparent,
                    borderRadius: TaskDetailTheme.checkRadius,
                    border: checked
                        ? null
                        : Border.all(
                            color: TaskDetailTheme.checkBorder,
                            width: 1.3,
                          ),
                  ),
                  child: checked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: TaskDetailTheme.surface,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subtask.title,
                    style: TaskDetailTheme.subtask.copyWith(
                      color: checked
                          ? TaskDetailTheme.muted
                          : dark
                          ? TaskDetailTheme.white
                          : AppColors.lightText,
                      decoration: checked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TintedChip extends StatelessWidget {
  const _TintedChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: TaskDetailTheme.pillRadius,
    ),
    child: Text(
      label,
      style: TaskDetailTheme.chip.copyWith(color: color.readable(context)),
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.item,
    required this.isDark,
    required this.dueLabel,
  });
  final TaskItem item;
  final bool isDark;
  final String dueLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? TaskDetailTheme.surface : AppColors.lightSurface,
      borderRadius: TaskDetailTheme.cardRadius,
      border: Border.all(
        color: isDark ? TaskDetailTheme.border : AppColors.lightBorder,
      ),
    ),
    child: Column(
      children: [
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: context.l10n.taskDue,
          value: dueLabel,
        ),
        const Divider(height: 10, color: TaskDetailTheme.border, indent: 48),
        _InfoRow(
          icon: Icons.person_outline_rounded,
          label: context.l10n.taskAssignedBy,
          value: item.assignee,
        ),
        const Divider(height: 10, color: TaskDetailTheme.border, indent: 48),
        _InfoRow(
          icon: Icons.flag_outlined,
          label: context.l10n.taskStatus,
          value: _taskLabel(context, item.status),
          statusChip: true,
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.statusChip = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool statusChip;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 40),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: TaskDetailTheme.blueTint,
            borderRadius: TaskDetailTheme.iconRadius,
          ),
          child: Icon(icon, size: 18, color: TaskDetailTheme.blueText),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TaskDetailTheme.label)),
        const SizedBox(width: 8),
        Flexible(
          child: statusChip
              ? _TintedChip(label: value, color: TaskDetailTheme.blueText)
              : Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TaskDetailTheme.value,
                ),
        ),
      ],
    ),
  );
}

class _CommentsPanel extends ConsumerWidget {
  const _CommentsPanel({required this.item, required this.isDark});

  final TaskItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.info,
              size: AppSizes.icon,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.taskCommentsCount(item.comments.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (item.comments.isEmpty)
          Text(context.l10n.taskNoComments)
        else
          for (final comment in item.comments)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceInset
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(comment),
            ),
        TextField(
          decoration: InputDecoration(
            labelText: context.l10n.taskAddComment,
            suffixIcon: Icon(Icons.send_rounded),
          ),
          onSubmitted: (comment) {
            if (comment.trim().isNotEmpty) {
              ref
                  .read(taskProvider.notifier)
                  .updateTask(item.id, comment: comment);
            }
          },
        ),
      ],
    ),
  );
}

/// Label tampilan untuk nilai prioritas/status/tenggat internal.
String _taskLabel(BuildContext context, String value) {
  final l10n = context.l10n;
  return switch (value.toLowerCase()) {
    'rendah' || 'low' => l10n.taskPriorityLow,
    'sedang' || 'medium' => l10n.taskPriorityMedium,
    'tinggi' || 'high' => l10n.taskPriorityHigh,
    'selesai' || 'done' || 'completed' => l10n.taskStatusDone,
    'berjalan' || 'dikerjakan' || 'in progress' => l10n.taskStatusInProgress,
    'hari ini' => l10n.taskDueToday,
    'besok' => l10n.taskDueTomorrow,
    'minggu ini' => l10n.taskDueWeek,
    'pilih' => l10n.taskDuePick,
    _ => value,
  };
}
