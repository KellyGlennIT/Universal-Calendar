import 'dart:async';
import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';
import '../utils/notification_sounds.dart';

/// Global notifier for currently ringing alarm settings.
/// When non-null, the in-app ringing screen is displayed.
final ValueNotifier<AlarmSettings?> activeRingingAlarm =
    ValueNotifier<AlarmSettings?>(null);

/// Stream subscriptions to listen for alarm state and native alarm events.
StreamSubscription? _alarmRingSubscription;
StreamSubscription? _alarmEventSubscription;

class CalendarAlarmService {
  CalendarAlarmService._();

  static const int _maxOccurrences = 60;
  static const int _rollingOccurrence = _maxOccurrences;
  static const int _snoozeOccurrence = _maxOccurrences + 1;
  static const int _testAlarmId = 999999;

  /// Initializes the native alarm service.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Alarm.init();

      // Restore the currently ringing alarm when Flutter starts after the
      // native alarm service has already launched the alarm.
      final currentlyRinging = Alarm.ringing.value.alarms;
      if (currentlyRinging.isNotEmpty) {
        activeRingingAlarm.value = currentlyRinging.first;
      }

      // Listen to the complete ringing set, not just the first alarm. Remove
      // the full-screen UI when every active alarm has been dismissed.
      _alarmRingSubscription?.cancel();
      _alarmRingSubscription = Alarm.ringing.listen((alarmSet) {
        final ringing = alarmSet.alarms;
        if (ringing.isEmpty) {
          activeRingingAlarm.value = null;
          return;
        }
        activeRingingAlarm.value = ringing.first;
        unawaited(_scheduleFollowingOccurrence(ringing.first));
      });

      // A platform refusal may defer an alarm; re-register the affected event
      // from its persisted event definition rather than leave it missed.
      _alarmEventSubscription?.cancel();
      _alarmEventSubscription = Alarm.events.listen((event) {
        debugPrint('[CalendarAlarmService] Native alarm event: $event');
        if (event case AlarmMoved(:final id, :final cause)
            when cause == AlarmEventCause.platformRefusal) {
          unawaited(_rescheduleAfterPlatformRefusal(id));
        }
      });
    } catch (e) {
      debugPrint('[CalendarAlarmService] Init error: $e');
    }
  }

  /// Requests the permissions required for timely alarm notifications.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      // Android 13+ needs notification permission for the package's ongoing
      // foreground-service alarm controls. Exact alarm access is separate.
      var notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        notificationStatus = await Permission.notification.request();
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        return notificationStatus.isGranted;
      }

      var exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (!exactAlarmStatus.isGranted) {
        exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      }
      return notificationStatus.isGranted && exactAlarmStatus.isGranted;
    } catch (e) {
      debugPrint('[CalendarAlarmService] Permission error: $e');
      return false;
    }
  }

  /// Whether notifications and, on Android, exact alarm access are granted.
  static Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      final notif = await Permission.notification.isGranted;
      if (!notif) return false;
      if (defaultTargetPlatform != TargetPlatform.android) return true;
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      debugPrint('[CalendarAlarmService] Permission check error: $e');
      return false;
    }
  }

  /// Open Android system app settings
  static Future<bool> openSystemAppSettings() => openAppSettings();

  /// Converts a string UUID to a stable positive 32-bit integer for the alarm plugin.
  static int alarmIdFor(String eventId, [int occurrence = 0]) {
    var hash = 0x811c9dc5;
    final combined = occurrence == 0 ? eventId : '$eventId#r$occurrence';
    for (final unit in combined.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    // Reserve 999900+ for tests & preview
    final id = hash % 990000;
    return id == 0 ? 1 : id;
  }

  /// Plays a test alarm immediately so the user can test their alarm tone and volume.
  static Future<void> sendTestNotification({String? toneId}) async {
    await previewTone(toneId);
  }

  /// Previews an alarm tone by triggering an immediate short-duration or test alarm.
  static Future<void> previewTone(String? toneId) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFrench = prefs.getString('app_language') == 'fr';
      final assetPath = alarmAssetPathFor(toneId);

      // Stop any existing test alarm
      await Alarm.stop(_testAlarmId);

      final settings = AlarmSettings(
        id: _testAlarmId,
        dateTime: DateTime.now().add(const Duration(milliseconds: 500)),
        assetAudioPath: assetPath,
        loopAudio: true,
        vibrate: true,
        androidAlarmClock: true,
        androidFullScreenIntent: false,
        androidStopAlarmOnTermination: false,
        warningNotificationOnKill: false,
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 1),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: isFrench ? 'Test de réveil' : 'Alarm Test',
          body: isFrench
              ? 'Le son de réveil fonctionne parfaitement !'
              : 'Alarm sound and vibration are working!',
          stopButton: isFrench ? 'Arrêter' : 'Stop Alarm',
          icon: 'ic_launcher',
        ),
      );

      final scheduled = await Alarm.set(alarmSettings: settings);
      if (!scheduled) {
        debugPrint('[CalendarAlarmService] Could not schedule preview alarm.');
      }
    } catch (e) {
      debugPrint('[CalendarAlarmService] Preview error: $e');
    }
  }

  /// Stops an active ringing alarm and clears the active screen.
  static Future<void> stopAlarm(int alarmId) async {
    if (kIsWeb) return;
    try {
      await Alarm.stop(alarmId);
      final remaining = Alarm.ringing.value.alarms;
      activeRingingAlarm.value = remaining.isEmpty ? null : remaining.first;
    } catch (e) {
      debugPrint('[CalendarAlarmService] Error stopping alarm $alarmId: $e');
    }
  }

  /// Snoozes an active ringing alarm by stopping it and scheduling a new one
  /// after [minutes] minutes.
  static Future<void> snoozeAlarm(int alarmId, {int minutes = 5}) async {
    if (kIsWeb) return;
    try {
      final current = activeRingingAlarm.value;
      if (current == null || current.id != alarmId) return;
      await Alarm.stop(alarmId);
      activeRingingAlarm.value = null;

      final newTime = DateTime.now().add(Duration(minutes: minutes));
      final snoozedSettings = AlarmSettings(
        id: current.payload == null
            ? alarmId
            : alarmIdFor(current.payload!, _snoozeOccurrence),
        dateTime: newTime,
        assetAudioPath: current.assetAudioPath,
        loopAudio: true,
        vibrate: true,
        androidAlarmClock: true,
        androidFullScreenIntent: false,
        androidStopAlarmOnTermination: false,
        warningNotificationOnKill: false,
        volumeSettings: current.volumeSettings,
        notificationSettings: current.notificationSettings,
        payload: current.payload,
      );
      final scheduled = await Alarm.set(alarmSettings: snoozedSettings);
      if (!scheduled) {
        debugPrint('[CalendarAlarmService] Could not schedule snoozed alarm.');
      }
    } catch (e) {
      debugPrint('[CalendarAlarmService] Error snoozing alarm: $e');
    }
  }

  /// Cancels all scheduled alarms for a given event ID.
  static Future<void> cancelEvent(String eventId) async {
    if (kIsWeb) return;
    try {
      final mainId = alarmIdFor(eventId);
      await Alarm.stop(mainId);
      for (var i = 0; i <= _rollingOccurrence; i++) {
        await Alarm.stop(alarmIdFor(eventId, i));
      }
      await Alarm.stop(alarmIdFor(eventId, _snoozeOccurrence));
      if (activeRingingAlarm.value?.payload == eventId) {
        activeRingingAlarm.value = null;
      }
    } catch (e) {
      debugPrint('[CalendarAlarmService] Could not cancel alarm: $e');
    }
  }

  /// Cancels all alarms across the app.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      final List<AlarmSettings> all = await Alarm.getAlarms();
      for (final a in all) {
        await Alarm.stop(a.id);
      }
      activeRingingAlarm.value = null;
    } catch (e) {
      debugPrint('[CalendarAlarmService] Could not cancel all alarms: $e');
    }
  }

  /// Schedules the next alarm occurrence(s) for [event].
  static Future<bool> scheduleEvent(CalendarEvent event) async {
    if (kIsWeb) return event.reminderMinutesBefore == null;
    try {
      await cancelEvent(event.id);

      final minutes = event.reminderMinutesBefore;
      if (minutes == null) return true;
      if (minutes < 0) return false;

      final dateParts = event.date.split('-').map(int.parse).toList();
      final timeParts = event.time.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length < 2) return false;

      final eventLocal = DateTime(
        dateParts[0],
        dateParts[1],
        dateParts[2],
        event.isAllDay ? 9 : timeParts[0],
        event.isAllDay ? 0 : timeParts[1],
      );
      final firstAlarmTime = eventLocal.subtract(Duration(minutes: minutes));

      final prefs = await SharedPreferences.getInstance();
      final isFrench = prefs.getString('app_language') == 'fr';
      final assetPath = alarmAssetPathFor(event.reminderSound);

      final body = minutes == 0
          ? (isFrench
              ? 'Votre événement commence maintenant.'
              : 'Your event is starting now.')
          : (isFrench
              ? 'Votre événement commence dans $minutes minutes.'
              : 'Your event starts in $minutes minutes.');

      final now = DateTime.now();

      if (event.repeatMode == 'once') {
        if (!firstAlarmTime.isAfter(now)) return false;
        final id = alarmIdFor(event.id);
        final scheduled = await Alarm.set(
          alarmSettings: _buildSettings(
            event: event,
            id: id,
            ringTime: firstAlarmTime,
            assetPath: assetPath,
            body: body,
            isFrench: isFrench,
          ),
        );
        if (!scheduled) return false;
        return true;
      }

      final firstCursor = firstAlarmTime.isAfter(now)
          ? firstAlarmTime
          : _nextOccurrence(firstAlarmTime, event.repeatMode);
      if (firstCursor == null) return false;
      DateTime cursor = firstCursor;

      if (event.repeatUntil == null) {
        return await Alarm.set(
          alarmSettings: _buildSettings(
            event: event,
            id: alarmIdFor(event.id),
            ringTime: cursor,
            assetPath: assetPath,
            body: body,
            isFrench: isFrench,
          ),
        );
      }

      final end = event.repeatUntil!;
      var index = 0;
      var scheduledCount = 0;
      while (index < _maxOccurrences &&
          _dateOnly(cursor.add(Duration(minutes: minutes)))
                  .compareTo(_dateOnly(end)) <=
              0) {
        final success = await Alarm.set(
          alarmSettings: _buildSettings(
            event: event,
            id: alarmIdFor(event.id, index),
            ringTime: cursor,
            assetPath: assetPath,
            body: body,
            isFrench: isFrench,
          ),
        );
        if (!success) {
          await cancelEvent(event.id);
          return false;
        }
        scheduledCount++;
        cursor = _nextDate(cursor, event.repeatMode);
        index++;
      }
      return scheduledCount > 0;
    } catch (e) {
      debugPrint('[CalendarAlarmService] Error scheduling alarm: $e');
      await cancelEvent(event.id);
      return false;
    }
  }

  static AlarmSettings _buildSettings({
    required CalendarEvent event,
    required int id,
    required DateTime ringTime,
    required String assetPath,
    required String body,
    required bool isFrench,
  }) {
    return AlarmSettings(
      id: id,
      dateTime: ringTime,
      assetAudioPath: assetPath,
      loopAudio: true,
      vibrate: true,
      androidAlarmClock: true,
      androidFullScreenIntent: false,
      androidStopAlarmOnTermination: false,
      warningNotificationOnKill: false,
      androidSnoozeDuration: Duration(minutes: event.snoozeMinutes),
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 2),
        volumeEnforced: event.alarmStyle,
      ),
      notificationSettings: NotificationSettings(
        title: event.title.isEmpty
            ? (isFrench ? 'Alarme Calendrier' : 'Calendar Alarm')
            : event.title,
        body: body,
        stopButton: isFrench ? 'Arrêter' : 'Stop Alarm',
        androidSnoozeButton: isFrench ? 'Répéter' : 'Snooze',
        androidStopAlarmOnDismiss: false,
        icon: 'ic_launcher',
      ),
      payload: event.id,
    );
  }

  static Future<void> _rescheduleAfterPlatformRefusal(int alarmId) async {
    try {
      final alarm = await Alarm.getAlarm(alarmId);
      final eventId = alarm?.payload;
      if (eventId == null || eventId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final rawEvents = prefs.getString('events');
      if (rawEvents == null) return;
      final events = jsonDecode(rawEvents) as List<dynamic>;
      final json = events.cast<Map>().firstWhere(
            (item) => item['id'] == eventId,
            orElse: () => <String, dynamic>{},
          );
      if (json.isEmpty) return;
      await scheduleEvent(CalendarEvent.fromJson(json));
    } catch (e) {
      debugPrint('[CalendarAlarmService] Refusal recovery failed: $e');
    }
  }

  static Future<void> _scheduleFollowingOccurrence(
      AlarmSettings ringingAlarm) async {
    final eventId = ringingAlarm.payload;
    if (eventId == null || eventId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawEvents = prefs.getString('events');
      if (rawEvents == null) return;
      final events = jsonDecode(rawEvents) as List<dynamic>;
      final eventJson = events.cast<Map>().firstWhere(
            (item) => item['id'] == eventId,
            orElse: () => <String, dynamic>{},
          );
      if (eventJson.isEmpty) return;
      final event = CalendarEvent.fromJson(eventJson);
      if (event.repeatMode == 'once' || event.reminderMinutesBefore == null) {
        return;
      }

      final scheduled = (await Alarm.getAlarms())
          .where((alarm) =>
              alarm.payload == eventId &&
              alarm.id != alarmIdFor(eventId, _snoozeOccurrence))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final latest =
          scheduled.isEmpty ? ringingAlarm.dateTime : scheduled.first.dateTime;
      var next = _nextDate(latest, event.repeatMode);
      if (!next.isAfter(DateTime.now())) {
        next = _nextOccurrence(next, event.repeatMode) ?? next;
      }
      final end = event.repeatUntil;
      if (end != null &&
          _dateOnly(next.add(Duration(minutes: event.reminderMinutesBefore!)))
                  .compareTo(_dateOnly(end)) >
              0) {
        return;
      }

      final ids = scheduled.map((alarm) => alarm.id).toSet();
      final availableIndex =
          List<int>.generate(_maxOccurrences, (i) => i).firstWhere(
        (i) =>
            alarmIdFor(eventId, i) != ringingAlarm.id &&
            !ids.contains(alarmIdFor(eventId, i)),
        orElse: () => -1,
      );
      final nextId = event.repeatUntil == null
          ? alarmIdFor(
              eventId,
              ringingAlarm.id == alarmIdFor(eventId) ? _rollingOccurrence : 0,
            )
          : availableIndex == -1
              ? -1
              : alarmIdFor(eventId, availableIndex);
      if (nextId == -1) return;

      final isFrench = prefs.getString('app_language') == 'fr';
      final minutes = event.reminderMinutesBefore!;
      final body = minutes == 0
          ? (isFrench
              ? 'Votre événement commence maintenant.'
              : 'Your event is starting now.')
          : (isFrench
              ? 'Votre événement commence dans $minutes minutes.'
              : 'Your event starts in $minutes minutes.');
      final success = await Alarm.set(
        alarmSettings: _buildSettings(
          event: event,
          id: nextId,
          ringTime: next,
          assetPath: alarmAssetPathFor(event.reminderSound),
          body: body,
          isFrench: isFrench,
        ),
      );
      if (!success) {
        debugPrint(
            '[CalendarAlarmService] Could not schedule next occurrence for $eventId.');
      }
    } catch (e) {
      debugPrint(
          '[CalendarAlarmService] Could not schedule next occurrence: $e');
    }
  }

  static DateTime? _nextOccurrence(DateTime candidate, String mode) {
    final now = DateTime.now();
    if (candidate.isAfter(now)) return candidate;
    var cursor = candidate;
    var guard = 0;
    while (!cursor.isAfter(now) && guard < 1000) {
      cursor = _nextDate(cursor, mode);
      guard++;
    }
    return cursor.isAfter(now) ? cursor : null;
  }

  static DateTime _nextDate(DateTime date, String mode) {
    final days = mode == 'daily' ? 1 : 7;
    return DateTime(
      date.year,
      date.month,
      date.day + days,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// Backwards compatibility alias so existing imports don't break.
typedef CalendarNotificationService = CalendarAlarmService;
