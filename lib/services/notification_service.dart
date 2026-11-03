import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/calendar_event.dart';

/// Holds the event ID from a tapped notification until the app's navigation
/// stack is ready to consume it (or `null` if no notification was tapped).
///
/// Written by `CalendarNotificationService.initialize()`'s tap handler and by
/// the cold-start launch check. Read by `MainScaffold._handleNotificationLaunch()`.
final ValueNotifier<String?> pendingNotificationEventId =
    ValueNotifier<String?>(null);

/// The local-notification engine.
///
/// Handles:
///   • Timezone-aware scheduling via `tz.TZDateTime`
///   • Android 13 POST_NOTIFICATIONS runtime permission
///   • Android 12+ SCHEDULE_EXACT_ALARM permission
///   • Automatic fallback to inexact alarms when exact permission is denied
///   • Cancel-before-reschedule (no orphan reminders)
///   • Cancel-all on reset
class CalendarNotificationService {
  CalendarNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'universal_calendar_alerts_v3',
    'Calendar alerts',
    description: 'Audible reminders and calendar alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialises the plugin, sets up the notification channel, installs the
  /// tap handler, and checks for a cold-start launch from a notification.
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
    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        pendingNotificationEventId.value = payload;
      }
    }
  }

  /// Requests notification and exact-alarm permissions. Returns `true` when
  /// POST_NOTIFICATIONS is granted (exact-alarm is best-effort).
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

  /// Fires an immediate test notification — used by Settings → "Test sound".
  static Future<void> sendTestNotification() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final isFrench = prefs.getString('app_language') == 'fr';
    await _plugin.show(
      9001,
      isFrench
          ? 'Les notifications fonctionnent'
          : 'Notifications are working',
      isFrench
          ? 'Calendrier universel peut émettre des rappels sonores sur cet appareil.'
          : 'Universal Calendar can play reminder sounds on this device.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  /// FNV-1a hash — gives a stable 31-bit int ID for a String event ID, so
  /// cancel can find the same slot that schedule used.
  static int _notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// Cancels the reminder tied to [eventId].
  static Future<void> cancelEvent(String eventId) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_notificationId(eventId));
    } catch (error) {
      debugPrint('Could not cancel calendar reminder: $error');
    }
  }

  /// Cancels every scheduled reminder — used on reset and on backup restore.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Could not cancel all reminders: $error');
    }
  }

  /// Schedules a reminder for [event] if `reminderMinutesBefore` is set and
  /// in the future. Cancels any existing reminder for the same event first.
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
          dateParts[0], dateParts[1], dateParts[2], timeParts[0], timeParts[1]);
      final reminderLocal =
          eventLocal.subtract(Duration(minutes: minutes));
      if (!reminderLocal.isAfter(DateTime.now())) return;
      final scheduled = tz.TZDateTime.from(reminderLocal, tz.local);
      final prefs = await SharedPreferences.getInstance();
      final isFrench = prefs.getString('app_language') == 'fr';
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exactAllowed =
          await android?.canScheduleExactNotifications() ?? false;
      final body = minutes == 0
          ? (isFrench
              ? 'Votre événement commence maintenant.'
              : 'Your event is starting now.')
          : (isFrench
              ? 'Votre événement commence dans $minutes minutes.'
              : 'Your event starts in $minutes minutes.');
      await _plugin.zonedSchedule(
        _notificationId(event.id),
        event.title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
            ticker: 'Calendar reminder',
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: exactAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: event.id,
      );
    } catch (error) {
      debugPrint('Could not schedule reminder for ${event.id}: $error');
    }
  }
}