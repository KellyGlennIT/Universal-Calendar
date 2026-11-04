import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/notification_sounds.dart';
import '../l10n/tr.dart';
import 'add_event_page.dart';

class EventDetailPage extends StatelessWidget {
  final CalendarEvent? event;
  const EventDetailPage({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<CalendarProvider>(context);

    final CalendarEvent selectedEvent;
    final widgetEvent = event;
    if (widgetEvent != null) {
      selectedEvent = provider.findEventById(widgetEvent.id) ?? widgetEvent;
    } else if (provider.eventsForSelectedDate.isNotEmpty) {
      selectedEvent = provider.eventsForSelectedDate.first;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'Event Details')),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(child: Text(tr(context, 'No event selected'))),
      );
    }

    final cal = provider.calendars.firstWhere(
      (c) => c.id == selectedEvent.calendarId,
      orElse: () => provider.calendars.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Event Details')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEventPage(eventToEdit: selectedEvent)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await confirmDelete(
                context,
                tr(context, 'Are you sure you want to delete this event?'),
              );
              if (confirmed && context.mounted) {
                provider.deleteEvent(selectedEvent.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────
            Row(children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: selectedEvent.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(selectedEvent.title,
                      style: Theme.of(context).textTheme.titleLarge)),
            ]),

            // ── Badges (multi-day, alarm, repeat) ────────────────────
            if (selectedEvent.isMultiDay ||
                selectedEvent.alarmStyle ||
                selectedEvent.repeatMode != 'once') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (selectedEvent.isMultiDay)
                    _badge(
                      context,
                      Icons.date_range,
                      _multiDayLabel(context, selectedEvent),
                      selectedEvent.color,
                    ),
                  if (selectedEvent.alarmStyle)
                    _badge(
                      context,
                      Icons.alarm,
                      tr(context, 'Alarm-style'),
                      Colors.orange.shade700,
                    ),
                  if (selectedEvent.repeatMode != 'once')
                    _badge(
                      context,
                      Icons.repeat,
                      selectedEvent.repeatMode == 'daily'
                          ? tr(context, 'Repeats daily')
                          : tr(context, 'Repeats weekly'),
                      Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // ── When / where / reminder card ────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start date
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          CalendarMath.formatDate(
                            CalendarMath.parseDate(
                                selectedEvent.date, 'YYYY-MM-DD'),
                            cal.dateFormat,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ]),

                    // End date (only for multi-day)
                    if (selectedEvent.isMultiDay) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.event_outlined,
                            size: 18, color: selectedEvent.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${tr(context, 'Ends')}: '
                            '${CalendarMath.formatDate(
                              CalendarMath.parseDate(
                                  selectedEvent.endDate!, 'YYYY-MM-DD'),
                              cal.dateFormat,
                            )}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ]),
                    ],

                    // Time
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedEvent.isAllDay
                              ? tr(context, 'All day')
                              : '${CalendarMath.formatTimeForCalendar(selectedEvent.time, provider.getEffectiveTimeFormat(cal), sunriseHour: provider.sunriseHour)} – '
                                  '${CalendarMath.formatTimeForCalendar(formatEventEnd(selectedEvent), provider.getEffectiveTimeFormat(cal), sunriseHour: provider.sunriseHour)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ]),

                    // Reminder
                    if (selectedEvent.reminderMinutesBefore != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${tr(context, 'Reminder')}: '
                            '${selectedEvent.reminderMinutesBefore == 0 ? tr(context, 'At event time') : '${selectedEvent.reminderMinutesBefore} min before'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ]),
                      // Reminder sound label
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          tr(context,
                              toneById(selectedEvent.reminderSound).label),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ),
                    ],

                    // Repeat until
                    if (selectedEvent.repeatMode != 'once' &&
                        selectedEvent.repeatUntil != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.event_repeat,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${tr(context, 'Until')} '
                            '${CalendarMath.formatDate(selectedEvent.repeatUntil!, cal.dateFormat)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ]),
                    ],

                    // Calendar
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.calendar_month, size: 18, color: cal.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cal.name,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Notes ────────────────────────────────────────────────
            if (selectedEvent.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.note, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(tr(context, 'Notes'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Text(selectedEvent.notes,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  String _multiDayLabel(BuildContext context, CalendarEvent event) {
    try {
      final start = CalendarMath.parseDate(event.date, 'YYYY-MM-DD');
      final end = CalendarMath.parseDate(event.endDate!, 'YYYY-MM-DD');
      final total = end.difference(start).inDays + 1;
      final today = DateTime.now();
      final dayNumber = DateTime(today.year, today.month, today.day)
              .difference(DateTime(start.year, start.month, start.day))
              .inDays +
          1;
      if (dayNumber >= 1 && dayNumber <= total) {
        return '$total ${tr(context, 'days')} · ${tr(context, 'Day')} $dayNumber';
      }
      return '$total ${tr(context, 'days')}';
    } catch (_) {
      return tr(context, 'Multi-day');
    }
  }

  Widget _badge(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}