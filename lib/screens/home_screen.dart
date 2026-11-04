import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../l10n/tr.dart';
import 'add_event_page.dart';
import 'day_view_page.dart';
import 'equivalents_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _viewMode = 'month';

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = context.watch<CalendarProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0A0E17), const Color(0xFF0D1119)]
              : [const Color(0xFFF0F4FF), const Color(0xFFF8F9FE)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _CalendarSelector(),
            const SizedBox(height: 12),
            const _MultiCalendarStrip(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'month',
                    label: Text(tr(context, 'Month'),
                        style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.calendar_view_month, size: 18),
                  ),
                  ButtonSegment(
                    value: 'week',
                    label: Text(tr(context, 'Week'),
                        style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.view_week, size: 18),
                  ),
                ],
                selected: {_viewMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    setState(() => _viewMode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            if (_viewMode == 'month') const _MonthPickerHeader(),
            if (_viewMode == 'month') const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.035, 0), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: _viewMode == 'month'
                    ? KeyedSubtree(
                        key: ValueKey(
                            'month-${provider.currentYear}-${provider.currentMonth}'),
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -180) {
                              provider.changeMonth(1);
                            } else if (velocity > 180) {
                              provider.changeMonth(-1);
                            }
                          },
                          child: const _CalendarGrid(),
                        ),
                      )
                    : const _WeekCalendarView(key: ValueKey('week')),
              ),
            ),
            _BottomBar(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CalendarProvider provider;
  const _BottomBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => provider.goToToday(),
              icon: const Icon(Icons.today_rounded, size: 18),
              label: Text(
                tr(context, 'Today'),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventPage()),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                tr(context, 'Add event'),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarSelector extends StatelessWidget {
  const _CalendarSelector();

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        if (provider.calendars.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                tr(context, 'No calendars. Create one from the drawer.')),
          );
        }
        final selected = provider.selectedCalendar;
        final color = selected?.color ?? Theme.of(context).primaryColor;

        return GestureDetector(
          onTap: () => _showPicker(context, provider),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.20),
                  child: Text(selected?.emoji ?? '📅',
                      style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected?.name ?? tr(context, 'Select Calendar'),
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (selected != null)
                        Text(
                          '${selected.daysPerWeek} ${tr(context, 'Days/week')} · '
                          '${selected.monthsPerYear} ${tr(context, 'months/year')}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context, CalendarProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(context, 'Select Calendar'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'Choose which calendar to display'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Divider(),
            ...provider.calendars.map((cal) {
              final isSelected = cal.id == provider.selectedCalendarId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      cal.color.withValues(alpha: isSelected ? 1.0 : 0.20),
                  child: Text(cal.emoji,
                      style: const TextStyle(fontSize: 16)),
                ),
                title: Text(
                  cal.name,
                  style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal),
                ),
                subtitle: Text(
                  '${cal.daysPerWeek} ${tr(context, 'Days/week')} · ${cal.monthsPerYear} ${tr(context, 'months/year')}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cal.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr(context, 'Active'),
                          style:
                              TextStyle(fontSize: 11, color: cal.color),
                        ),
                      )
                    : null,
                onTap: () {
                  provider.selectCalendar(cal.id);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MultiCalendarStrip extends StatelessWidget {
  const _MultiCalendarStrip();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    if (provider.calendars.length < 2) return const SizedBox.shrink();

    final anchor = provider.selectedDate;

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.calendars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cal = provider.calendars[index];
          final isSelected = cal.id == provider.selectedCalendarId;
          final info = CalendarMath.getCalendarDateInfo(cal, anchor);
          return GestureDetector(
            onTap: () => provider.selectCalendar(cal.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cal.color.withValues(alpha: 0.18)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? cal.color.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cal.emoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        cal.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cal.color : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${info['day']} ${info['monthName']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? cal.color : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthPickerHeader extends StatelessWidget {
  const _MonthPickerHeader();

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        final cal = provider.selectedCalendar;
        final localeCode = context.watch<LocaleProvider>().languageCode;
        final String monthName;
        if (cal == null) {
          monthName = DateFormat('MMMM', localeCode)
              .format(DateTime(provider.currentYear, provider.currentMonth));
        } else {
          final info =
              CalendarMath.getCalendarDateInfo(cal, provider.anchorDate);
          monthName = (info['monthName'] as String?) ??
              DateFormat('MMMM', localeCode).format(provider.anchorDate);
        }
        final totalMonths = cal?.fullMonthNames.length ?? 12;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _iconButton(
                context,
                icon: Icons.chevron_left,
                onTap: () => provider.changeMonth(-1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      monthName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${provider.currentYear}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tr(context, 'Month')} ${provider.currentMonth} ${tr(context, 'of')} $totalMonths',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _iconButton(
                context,
                icon: Icons.chevron_right,
                onTap: () => provider.changeMonth(1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 20, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

class _WeekCalendarView extends StatelessWidget {
  const _WeekCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = context.watch<CalendarProvider>();
    final selected = provider.selectedDate;
    final cal = provider.selectedCalendar;
    if (cal == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final dayCount = cal.daysPerWeek.clamp(1, 14).toInt();
    final first = DateTime(selected.year, selected.month, selected.day)
        .subtract(Duration(
            days: CalendarMath.getWeekStartOffset(cal, selected)));
    final configuredStart = cal.dayNames.indexOf(cal.weekStartDay);
    final startIndex = configuredStart < 0 ? 0 : configuredStart % dayCount;
    final localeCode = context.watch<LocaleProvider>().languageCode;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 180) return;
        provider.selectDate(selected
            .add(Duration(days: velocity < 0 ? dayCount : -dayCount)));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${DateFormat('d MMM', localeCode).format(first)} – '
                  '${DateFormat('d MMM y', localeCode).format(first.add(Duration(days: dayCount - 1)))}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.swipe,
                    size: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(
                  'swipe',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: List.generate(dayCount, (i) {
                final date = first.add(Duration(days: i));
                final isSelected = date.year == selected.year &&
                    date.month == selected.month &&
                    date.day == selected.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final info = CalendarMath.getCalendarDateInfo(cal, date);
                final events = provider.eventsForDate(date);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => provider.selectDate(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : isToday
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.10)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cal.calendarType == 'gregorian'
                                ? DateFormat('EEE', localeCode)
                                    .format(date)
                                : (cal.dayNames.isNotEmpty
                                    ? cal.dayNames[(startIndex + i) %
                                        cal.dayNames.length]
                                    : DateFormat('E').format(date)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white70
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${info['day']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: events.isEmpty
                                  ? Colors.transparent
                                  : isSelected
                                      ? Colors.white
                                      : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(dayCount, (i) {
            final date = first.add(Duration(days: i));
            final events = provider.eventsForDate(date);
            final isSelected = date.year == selected.year &&
                date.month == selected.month &&
                date.day == selected.day;
            final info = CalendarMath.getCalendarDateInfo(cal, date);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: isSelected
                    ? Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.06)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    provider.selectDate(date);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DayViewPage(selectedDate: date)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 46,
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE', localeCode)
                                    .format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${info['day']}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 2,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.4)
                                : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: events.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  child: Text(
                                    tr(context, 'No events'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ...events.take(3).map((event) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 3,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: event.color,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    event.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style:
                                                        const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    event.isAllDay
                                                        ? tr(context,
                                                            'All day')
                                                        : '${event.time}–${formatEventEnd(event)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(
                                                              context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    if (events.length > 3)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '+${events.length - 3} ${tr(context, 'events')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        final cal = provider.selectedCalendar;
        if (cal == null) {
          return Center(child: Text(tr(context, 'Select a calendar')));
        }
        final secondaryCal = provider.secondaryCalendarId != null
            ? provider.calendars.firstWhere(
                (c) => c.id == provider.secondaryCalendarId,
                orElse: () => cal,
              )
            : null;
        final currentDateInfo =
            CalendarMath.getCalendarDateInfo(cal, provider.anchorDate);
        final dayOfMonth = currentDateInfo['day'] as int;
        final firstDayGreg =
            provider.anchorDate.subtract(Duration(days: dayOfMonth - 1));
        final startOffset =
            CalendarMath.getWeekStartOffset(cal, firstDayGreg);
        final daysInMonth = CalendarMath.getDaysInMonthForCalendar(
            cal, provider.currentYear, provider.currentMonth);
        final localeCode = context.watch<LocaleProvider>().languageCode;
        final dayCount = cal.daysPerWeek.clamp(1, 14).toInt();
        final useLocalized = cal.calendarType == 'gregorian' &&
            (listEquals(cal.dayNames,
                    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) ||
                listEquals(cal.dayNames, const [
                  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                  'Friday', 'Saturday', 'Sunday',
                ]));
        final baseWeekdayNames = useLocalized
            ? List<String>.generate(
                7,
                (i) => DateFormat('EEE', localeCode)
                    .format(DateTime(2024, 1, 1 + i)))
            : cal.shortDayNames;
        final configuredStart = cal.dayNames.indexOf(cal.weekStartDay);
        final headerStart =
            configuredStart < 0 ? 0 : configuredStart % baseWeekdayNames.length;
        final weekdayNames = List<String>.generate(
            dayCount,
            (i) =>
                baseWeekdayNames[(headerStart + i) % baseWeekdayNames.length]);

        final headers = weekdayNames.map((name) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              name.length > 4
                  ? name.substring(0, 3).toUpperCase()
                  : name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.5),
                  ),
            ),
          );
        }).toList();

        final eventsByCalendarAndDate = <String, Set<String>>{};
        for (final e in provider.events) {
          eventsByCalendarAndDate
              .putIfAbsent(e.calendarId, () => <String>{})
              .add(e.date);
        }

        final specialDaysByDay = <int, List<dynamic>>{};
        for (final sd in cal.specialDays) {
          if (sd.month != provider.currentMonth) continue;
          specialDaysByDay.putIfAbsent(sd.day, () => []).add(sd);
        }

        final cells = <Widget>[];
        for (int i = 0; i < startOffset; i++) {
          cells.add(const SizedBox());
        }
        for (int day = 1; day <= daysInMonth; day++) {
          final date = firstDayGreg.add(Duration(days: day - 1));
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;
          final isSelected = date.year == provider.selectedDate.year &&
              date.month == provider.selectedDate.month &&
              date.day == provider.selectedDate.day;
          final isSabbath = (cal.calendarType == 'gregorian' ||
                  cal.calendarType == 'ethiopian' ||
                  cal.calendarType == 'biblical') &&
              date.weekday == DateTime.saturday;
          final dateStr = CalendarMath.formatDate(date, 'YYYY-MM-DD');
          final hasEvents =
              eventsByCalendarAndDate[cal.id]?.contains(dateStr) ?? false;
          final specialHere = specialDaysByDay[day];
          String? secondaryText;
          if (secondaryCal != null && secondaryCal.id != cal.id) {
            final info =
                CalendarMath.getCalendarDateInfo(secondaryCal, date);
            secondaryText = '${info['monthName']} ${info['day']}';
          }
          cells.add(GestureDetector(
            onLongPress: () => _showDateOptions(context, date, provider),
            onTap: () {
              provider.selectDate(date);
              HapticFeedback.selectionClick();
            },
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isToday
                        ? Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.15)
                        : null,
                border: isSabbath && !isSelected
                    ? Border.all(
                        color: const Color(0xFFD4AF37), width: 1.5)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (secondaryText != null)
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? Colors.white70
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (hasEvents)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  if (specialHere != null && specialHere.isNotEmpty)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: specialHere.first.color,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / dayCount;
            final aspect = cellWidth < 46 ? 0.82 : 1.0;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 26,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: dayCount,
                      childAspectRatio: 1,
                      children: headers,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      physics: const BouncingScrollPhysics(),
                      crossAxisCount: dayCount,
                      childAspectRatio: aspect,
                      children: cells,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDateOptions(
      BuildContext context, DateTime date, CalendarProvider provider) {
    final dateStr = CalendarMath.formatDate(date, 'YYYY-MM-DD');
    final eventsForDate = provider.events
        .where((e) =>
            e.date == dateStr &&
            e.calendarId == provider.selectedCalendarId)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CalendarMath.formatDate(date, 'DD/MM/YYYY'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            _tile(context, Icons.view_day, 'Open Day View',
                'See full day timeline', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DayViewPage(selectedDate: date)),
              );
            }),
            _tile(context, Icons.event, tr(context, 'Add Event'),
                tr(context, 'Add an event on this date'), () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventPage()),
              );
            }),
            _tile(context, Icons.list_alt, 'View Events',
                '${eventsForDate.length} events on this date', () {
              Navigator.pop(context);
              provider.selectDate(date);
              if (eventsForDate.isNotEmpty) {
                _showEventsList(context, eventsForDate);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(tr(context, 'No events on this date'))),
                );
              }
            }),
            _tile(context, Icons.swap_horiz,
                tr(context, 'Find Equivalents'),
                'See this date in all calendars', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EquivalentsPage(initialDate: date)),
              );
            }),
            if (eventsForDate.isNotEmpty)
              _tile(context, Icons.delete_outline, 'Clear All Events',
                  'Delete all events on this date', () {
                Navigator.pop(context);
                _confirmDeleteAll(context, dateStr);
              }, color: Colors.red),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.15),
        radius: 22,
        child: Icon(icon,
            size: 20, color: color ?? Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: onTap,
    );
  }

  void _showEventsList(BuildContext context, List<dynamic> events) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Events')),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: event.color),
                ),
                title: Text(event.title),
                subtitle: Text(
                    '${event.time} - ${event.notes.isNotEmpty ? event.notes : 'No notes'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final confirmed = await confirmDelete(
                      context,
                      tr(context,
                          'Are you sure you want to delete this event?'),
                    );
                    if (confirmed && context.mounted) {
                      Provider.of<CalendarProvider>(context,
                              listen: false)
                          .deleteEvent(event.id);
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Close')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, String dateStr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Delete All Events')),
        content: Text(tr(context,
            'Are you sure you want to delete all events on this date?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              final provider =
                  Provider.of<CalendarProvider>(context, listen: false);
              final toDelete = provider.events
                  .where((e) =>
                      e.date == dateStr &&
                      e.calendarId == provider.selectedCalendarId)
                  .toList();
              for (final e in toDelete) {
                provider.deleteEvent(e.id);
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr(context, 'Delete All')),
          ),
        ],
      ),
    );
  }
}