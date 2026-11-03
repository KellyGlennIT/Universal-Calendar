import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';
import 'add_event_page.dart';
import 'equivalents_page.dart';
import 'event_detail_page.dart';

class DayViewPage extends StatefulWidget {
  final DateTime selectedDate;
  const DayViewPage({super.key, required this.selectedDate});

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CalendarProvider>(context, listen: false)
            .selectDate(_currentDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<CalendarProvider>(context);
    final cal = provider.selectedCalendar;
    final secondaryCal = provider.secondaryCalendarId != null && cal != null
        ? provider.calendars.firstWhere(
            (c) => c.id == provider.secondaryCalendarId,
            orElse: () => cal,
          )
        : null;
    final localeCode = context.watch<LocaleProvider>().languageCode;
    final dateStr = CalendarMath.formatDate(_currentDate, 'YYYY-MM-DD');
    final dayEvents = provider.events
        .where((e) =>
            e.date == dateStr && e.calendarId == provider.selectedCalendarId)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
    final timedEvents = dayEvents.where((e) => !e.isAllDay).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() => _currentDate = DateTime.now());
              provider.goToToday();
            },
            tooltip: tr(context, 'Today'),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EquivalentsPage(initialDate: _currentDate)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEventPage()),
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM dd, yyyy', localeCode)
                  .format(_currentDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            if (secondaryCal != null)
              Builder(builder: (_) {
                final info = CalendarMath.getCalendarDateInfo(
                    secondaryCal, _currentDate);
                return Text(
                  '${info['monthName']} ${info['day']}, ${info['year']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              }),
          ],
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -180) {
            setState(() => _currentDate =
                _currentDate.add(const Duration(days: 1)));
            provider.selectDate(_currentDate);
          } else if (velocity > 180) {
            setState(() => _currentDate =
                _currentDate.subtract(const Duration(days: 1)));
            provider.selectDate(_currentDate);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0E17), Color(0xFF1A1F2E)],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cal != null)
                  Builder(builder: (_) {
                    final dateInfo =
                        CalendarMath.getCalendarDateInfo(cal, _currentDate);
                    final special = cal.specialDays
                        .where((sd) =>
                            sd.month == (dateInfo['month'] as int) &&
                            sd.day == (dateInfo['day'] as int))
                        .toList();
                    if (special.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: special
                            .map((sd) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sd.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            sd.color.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(sd.emoji,
                                          style: const TextStyle(
                                              fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        sd.name,
                                        style: TextStyle(
                                          color: sd.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    '${dayEvents.length} ${dayEvents.length == 1 ? tr(context, 'Event') : tr(context, 'Events')}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (allDayEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: allDayEvents
                          .map((event) => ActionChip(
                                avatar: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: event.color),
                                label: Text(event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailPage(event: event)),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                Expanded(child: _buildTimeline(context, timedEvents)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEventPage()),
        ),
        tooltip: tr(context, 'Add event'),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<CalendarEvent> events) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final cal = provider.selectedCalendar;
    if (cal == null) {
      return Center(child: Text(tr(context, 'Select a calendar')));
    }
    final effectiveFormat = provider.getEffectiveTimeFormat(cal);
    final showSeconds = provider.showSeconds;
    final showDayNight = provider.showDayNight;
    final sunriseHour = provider.sunriseHour;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 24,
      itemBuilder: (context, hour) {
        final hourEvents = events
            .where((e) => CalendarMath.getHourFromTimeString(e.time) == hour)
            .toList();

        String hourLabel;
        if (effectiveFormat == 'biblical') {
          hourLabel =
              CalendarMath.getBiblicalTime(hour, 0, sunriseHour: sunriseHour);
        } else if (effectiveFormat == '12h') {
          final ampm = hour >= 12 ? 'PM' : 'AM';
          final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          hourLabel = showSeconds ? '$h12:00:00 $ampm' : '$h12:00 $ampm';
        } else {
          hourLabel = showSeconds
              ? '${hour.toString().padLeft(2, '0')}:00:00'
              : '${hour.toString().padLeft(2, '0')}:00';
        }

        final isDaylight = hour >= sunriseHour && hour < sunriseHour + 12;
        final icon = showDayNight
            ? (isDaylight ? Icons.wb_sunny : Icons.nightlight_round)
            : Icons.circle;

        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: Column(
            children: [
              Row(children: [
                if (showDayNight) Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hourLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              if (hourEvents.isNotEmpty)
                ...hourEvents.map((event) => _TimelineItem(
                      event: event,
                      timeDisplay: event.isAllDay
                          ? tr(context, 'All day')
                          : '${_formatEventTime(event.time, effectiveFormat, showSeconds, sunriseHour)} – '
                              '${_formatEventTime(_eventEndTime(event), effectiveFormat, showSeconds, sunriseHour)}',
                      secondaryTimeDisplay: _formatEventTime(
                          event.time, cal.timeFormat, showSeconds, sunriseHour),
                      isFirst: hourEvents.first.id == event.id,
                      isLast: hourEvents.last.id == event.id,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: event)),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  String _eventEndTime(CalendarEvent event) {
    final parts = event.time.split(':');
    final start = DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    final end = start.add(Duration(minutes: event.durationMinutes));
    return '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}';
  }

  String _formatEventTime(
      String timeStr, String format, bool showSeconds, int sunriseHour) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (format == 'biblical') {
      return CalendarMath.getBiblicalTime(hour, minute,
          sunriseHour: sunriseHour);
    } else if (format == '12h') {
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      String result = '$h12:${minute.toString().padLeft(2, '0')}';
      if (showSeconds) result += ':00';
      return '$result $ampm';
    } else {
      String result =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      if (showSeconds) result += ':00';
      return result;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final CalendarEvent event;
  final String timeDisplay;
  final String? secondaryTimeDisplay;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.event,
    required this.timeDisplay,
    this.secondaryTimeDisplay,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeDisplay,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                if (secondaryTimeDisplay != null)
                  Text(
                    secondaryTimeDisplay!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          if (event.notes.isNotEmpty)
                            Text(
                              event.notes,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}