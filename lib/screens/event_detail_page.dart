import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
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
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ],
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
}