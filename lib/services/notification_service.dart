import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../models/calendar_event.dart';
import '../utils/notification_sounds.dart';

final ValueNotifier<String?> pendingNotificationEventId =
    ValueNotifier<String?>(null);

class CalendarNotificationService {
  CalendarNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelBaseId = 'uc_calendar_alerts_v6';
  static int _testSeq = 9000;
  static const int _maxOccurrences = 100;
  static const int _escalationCount = 4;

  static String _slug(String? s) {
    if (s == null || s.isEmpty) return 'default';
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  static String _channelIdForTone(String? toneId) =>
      '${_channelBaseId}_${_slug(toneId)}';

  static AndroidNotificationChannel _buildChannel(String? toneId) {
    return AndroidNotificationChannel(
      _channelIdForTone(toneId),
      'Calendar alerts',
      description: 'Audible reminders and calendar alerts',
      importance: Importance.max,
      playSound: true,
      sound: androidNotificationSoundFor(toneId),
      enableVibration: true,
    );
  }

  static Future<AndroidNotificationChannel> _ensureChannel(
      String? toneId) async {
    final channel = _buildChannel(toneId);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    return channel;
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (error) {
      debugPrint('Could not read device timezone: $error');
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Douala'));
      } catch (_) {}
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          pendingNotificationEventId.value = response.payload;
        }
      },
    );
    await _ensureChannel(null);

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        pendingNotificationEventId.value = payload;
      }
    }
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      var allowed = await android.areNotificationsEnabled() ?? false;
      if (!allowed) {
        allowed = await android.requestNotificationsPermission() ?? false;
      }
      if (allowed) {
        final exact = await android.canScheduleExactNotifications();
        if (exact != true) {
          final prefs = await SharedPreferences.getInstance();
          final asked = prefs.getBool('exact_alarm_prompted') ?? false;
          if (!asked) {
            await prefs.setBool('exact_alarm_prompted', true);
            try {
              await android.requestExactAlarmsPermission();
            } catch (_) {}
          }
        }
      }
      return allowed;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  static Future<bool> requestFullScreenIntentPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    try {
      final granted = await android.requestFullScreenIntentPermission();
      return granted ?? false;
    } catch (error) {
      debugPrint('Full-screen intent permission error: $error');
      return false;
    }
  }

  static Future<bool> openSystemAppSettings() => openAppSettings();

  static Future<void> previewTone(String? toneId) =>
      sendTestNotification(toneId: toneId);

  static Future<void> sendTestNotification({String? toneId}) async {
    if (kIsWeb) return;
    final channel = await _ensureChannel(toneId);

    final prefs = await SharedPreferences.getInstance();
    final isFrench = prefs.getString('app_language') == 'fr';
    final id = ++_testSeq;

    await _plugin.show(
      id,
      isFrench
          ? 'Les notifications fonctionnent'
          : 'Notifications are working',
      isFrench
          ? 'Calendrier universel peut émettre des rappels sonores sur cet appareil.'
          : 'Universal Calendar can play reminder sounds on this device.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.max,
          playSound: true,
          sound: channel.sound,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: iosSoundFor(toneId),
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  static int _notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static Future<void> cancelEvent(String eventId) async {
    if (kIsWeb) return;
    try {
      final futures = <Future<void>>[
        _plugin.cancel(_notificationId(eventId)),
      ];
      for (var i = 0; i < _maxOccurrences; i++) {
        futures.add(_plugin.cancel(_notificationId('$eventId#r$i')));
      }
      for (var i = 1; i <= _escalationCount; i++) {
        futures.add(_plugin.cancel(_notificationId('$eventId#esc$i')));
      }
      await Future.wait(futures);
    } catch (error) {
      debugPrint('Could not cancel calendar reminder: $error');
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Could not cancel all reminders: $error');
    }
  }

  static Future<void> scheduleEvent(CalendarEvent event) async {
    if (kIsWeb) return;
    try {
      await cancelEvent(event.id);

      final minutes = event.reminderMinutesBefore;
      if (minutes == null || minutes < 0) return;

      final dateParts = event.date.split('-').map(int.parse).toList();
      final timeParts = event.time.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length < 2) return;

      final eventLocal = DateTime(
        dateParts[0],
        dateParts[1],
        dateParts[2],
        timeParts[0],
        timeParts[1],
      );
      final firstReminder =
          eventLocal.subtract(Duration(minutes: minutes));

      final prefs = await SharedPreferences.getInstance();
      final isFrench = prefs.getString('app_language') == 'fr';
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exactAllowed =
          await android?.canScheduleExactNotifications() ?? false;
      final channel = await _ensureChannel(event.reminderSound);

      final body = minutes == 0
          ? (isFrench
              ? 'Votre événement commence maintenant.'
              : 'Your event is starting now.')
          : (isFrench
              ? 'Votre événement commence dans $minutes minutes.'
              : 'Your event starts in $minutes minutes.');

      final scheduleMode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final canEscalate =
          event.escalatingReminder && event.repeatMode == 'once';

      final baseDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.max,
          playSound: true,
          sound: channel.sound,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: event.alarmStyle,
          ticker: 'Calendar reminder',
          visibility: NotificationVisibility.public,
          additionalFlags:
              canEscalate ? Int32List.fromList(<int>[4]) : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: iosSoundFor(event.reminderSound),
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      if (event.repeatMode == 'once') {
        if (!firstReminder.isAfter(DateTime.now())) return;
        await _plugin.zonedSchedule(
          _notificationId(event.id),
          event.title,
          body,
          tz.TZDateTime.from(firstReminder, tz.local),
          baseDetails,
          androidScheduleMode: scheduleMode,
          payload: event.id,
        );
      } else if (event.repeatUntil == null) {
        final next = _nextOccurrence(firstReminder, event.repeatMode);
        if (next == null) return;
        await _plugin.zonedSchedule(
          _notificationId(event.id),
          event.title,
          body,
          tz.TZDateTime.from(next, tz.local),
          baseDetails,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: event.repeatMode == 'daily'
              ? DateTimeComponents.time
              : DateTimeComponents.dayOfWeekAndTime,
          payload: event.id,
        );
      } else {
        final step =
            Duration(days: event.repeatMode == 'daily' ? 1 : 7);
        final end = event.repeatUntil!;
        var cursor = firstReminder;
        var index = 0;
        final now = DateTime.now();
        while (index < _maxOccurrences && !cursor.isAfter(end)) {
          if (cursor.isAfter(now)) {
            await _plugin.zonedSchedule(
              _notificationId('${event.id}#r$index'),
              event.title,
              body,
              tz.TZDateTime.from(cursor, tz.local),
              baseDetails,
              androidScheduleMode: scheduleMode,
              payload: event.id,
            );
          }
          cursor = cursor.add(step);
          index++;
        }
      }

      if (canEscalate && firstReminder.isAfter(DateTime.now())) {
        for (var i = 1; i <= _escalationCount; i++) {
          final escalateAt =
              firstReminder.add(Duration(seconds: 30 * i));
          if (!escalateAt.isAfter(DateTime.now())) continue;
          await _plugin.zonedSchedule(
            _notificationId('${event.id}#esc$i'),
            event.title,
            body,
            tz.TZDateTime.from(escalateAt, tz.local),
            baseDetails,
            androidScheduleMode: scheduleMode,
            payload: event.id,
          );
        }
      }
    } catch (error) {
      debugPrint('Could not schedule reminder for ${event.id}: $error');
    }
  }

  static DateTime? _nextOccurrence(DateTime candidate, String mode) {
    final now = DateTime.now();
    if (candidate.isAfter(now)) return candidate;
    final step = Duration(days: mode == 'daily' ? 1 : 7);
    var cursor = candidate;
    var guard = 0;
    while (!cursor.isAfter(now) && guard < 1000) {
      cursor = cursor.add(step);
      guard++;
    }
    return cursor.isAfter(now) ? cursor : null;
  }

  static Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return false;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  static Future<bool> openAppSettingsForMicrophone() async {
    if (kIsWeb) return false;
    return openAppSettings();
  }
}