import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/tr.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';

/// In-app event alarm screen.
///
class AlarmRingingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({
    super.key,
    required this.alarmSettings,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    await CalendarAlarmService.stopAlarm(widget.alarmSettings.id);
  }

  Future<void> _snoozeAlarm(int minutes) async {
    await CalendarAlarmService.snoozeAlarm(
      widget.alarmSettings.id,
      minutes: minutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.watch<LocaleProvider>().languageCode;
    final calendarProvider = context.watch<CalendarProvider>();

    final eventId = widget.alarmSettings.payload;
    final event =
        eventId != null ? calendarProvider.findEventById(eventId) : null;

    final title = event?.title.isNotEmpty == true
        ? event!.title
        : (widget.alarmSettings.notificationSettings.title.isNotEmpty
            ? widget.alarmSettings.notificationSettings.title
            : tr(context, 'Calendar Alarm'));

    final notes = event?.notes ?? '';
    final uses12HourTime = event != null &&
        calendarProvider.calendars.any((calendar) =>
            calendar.id == event.calendarId && calendar.timeFormat == '12h');
    final nowFormatted = DateFormat(
      uses12HourTime ? 'h:mm a' : 'HH:mm',
      localeCode,
    ).format(DateTime.now());
    final eventDate = event == null ? null : DateTime.tryParse(event.date);
    final eventTime = event == null
        ? null
        : [
            event.isAllDay ? tr(context, 'All day') : event.time,
            if (eventDate != null)
              DateFormat.yMMMd(localeCode).format(eventDate),
          ].join(' · ');
    final snoozeMinutes = event?.snoozeMinutes ?? 5;

    return Scaffold(
      backgroundColor: const Color(0xFF10121A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top header badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_on,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          tr(context, 'ALARM RINGING').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pulsing Center Display
                  Column(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.access_alarm,
                              size: 70,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        nowFormatted,
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (eventTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${tr(context, 'Event time')}: $eventTime',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Keep snooze distinct from the alarm-dismiss action.
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B82FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _snoozeAlarm(snoozeMinutes),
                          icon: const Icon(Icons.snooze, size: 26),
                          label: Text(
                            '${tr(context, 'Snooze for')} $snoozeMinutes ${tr(context, 'minutes')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _stopAlarm,
                          icon:
                              const Icon(Icons.stop_circle_outlined, size: 22),
                          label: Text(
                            tr(context, 'Stop Alarm'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
