import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/theme_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/widgets/task_card.dart';
import '../../tasks/widgets/add_task_bottom_sheet.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// Takvim görünümü - Haftalık ve Aylık
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksForDate = ref.watch(tasksForSelectedDateProvider);
    final taskDates = ref.watch(taskDatesProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Takvim'),
        actions: [
          // Tema değiştirme butonu
          IconButton(
            icon: Icon(
              ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeModeNotifierProvider) == ThemeMode.dark
                ? 'Aydınlık Mod'
                : 'Karanlık Mod',
            onPressed: () {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),
          // Format değiştirme butonu
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week_outlined
                  : Icons.calendar_view_month_outlined,
            ),
            tooltip: _calendarFormat == CalendarFormat.month
                ? 'Haftalık Görünüm'
                : 'Aylık Görünüm',
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Takvim
          _buildCalendar(
            colorScheme,
            textTheme,
            selectedDate,
            taskDates,
          ),

          // Seçili tarih başlığı
          _buildDateHeader(colorScheme, textTheme, selectedDate, tasksForDate),

          // Görev listesi
          Expanded(
            child: tasksForDate.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.event_available,
                    title: 'Bugün görev yok',
                    subtitle: 'Yeni görev eklemek için + butonuna tıklayın',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: tasksForDate.length,
                    itemBuilder: (context, index) {
                      return TaskCard(
                        task: tasksForDate[index],
                        showDate: false,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTaskBottomSheet.show(
          context,
          initialDate: selectedDate,
        ),
        tooltip: 'Görev Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DateTime selectedDate,
    Map<DateTime, List<Task>> taskDates,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: TableCalendar<Task>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        locale: 'tr_TR',
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 42,
        daysOfWeekHeight: 20,
        
        // Seçim
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selected, focused) {
          ref.read(selectedDateProvider.notifier).state = selected;
          setState(() {
            _focusedDay = focused;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },

        // Event loader
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return taskDates[normalizedDay] ?? [];
        },

        // Stil
        calendarStyle: CalendarStyle(
          // Bugün
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(51),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),

          // Seçili gün
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),

          // Hafta sonu
          weekendTextStyle: TextStyle(
            color: colorScheme.error.withAlpha(179),
          ),

          // Dışarıdaki günler
          outsideDaysVisible: true,
          outsideTextStyle: TextStyle(
            color: colorScheme.onSurface.withAlpha(77),
          ),

          // Varsayılan
          defaultTextStyle: TextStyle(
            color: colorScheme.onSurface,
          ),

          // Event marker
          markerDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markersMaxCount: 3,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),

        // Header stili
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface,
          ),
          titleTextStyle: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),

        // Gün isimleri stili
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.error.withAlpha(179),
            fontWeight: FontWeight.w600,
          ),
        ),

        // Event marker builder (özelleştirilmiş)
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;

            // Görevlerin tamamlanma durumuna göre renk
            final hasIncomplete = events.any((t) => !t.isCompleted);
            final allCompleted = events.every((t) => t.isCompleted);

            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: allCompleted
                          ? const Color(0xFF10B981)
                          : hasIncomplete
                              ? colorScheme.primary
                              : colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (events.length > 1) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  if (events.length > 2) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(77),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DateTime selectedDate,
    List<Task> tasks,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    String dateLabel;
    if (selected == today) {
      dateLabel = 'Bugün';
    } else if (selected == today.add(const Duration(days: 1))) {
      dateLabel = 'Yarın';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Dün';
    } else {
      dateLabel = DateFormat('d MMMM, EEEE', 'tr_TR').format(selectedDate);
    }

    final completedCount = tasks.where((t) => t.isCompleted).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tasks.isEmpty
                    ? 'Görev yok'
                    : '${tasks.length} görev${completedCount > 0 ? ', $completedCount tamamlandı' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
              ),
            ],
            ),
          ),
          const SizedBox(width: 12),
          // İlerleme göstergesi
          if (tasks.isNotEmpty)
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completedCount / tasks.length,
                    backgroundColor: colorScheme.outlineVariant,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation(
                      completedCount == tasks.length
                          ? const Color(0xFF10B981)
                          : colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${((completedCount / tasks.length) * 100).round()}%',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
