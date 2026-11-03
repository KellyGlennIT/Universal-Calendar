# Universal Calendar

Universal Calendar is a Flutter calendar workspace built around user-defined calendar systems rather than a Gregorian-only calendar. It retains Gregorian, Ethiopian, Biblical and user-created calendars, dual-calendar comparison, custom month and weekday structures, date equivalents, offset calculations and the existing Christian utility screens.

## Target environment

- Target Flutter installation: **Flutter 3.47.5**
- Dart constraint: `>=3.4.0 <4.0.0`
- Android notifications: `flutter_local_notifications 19.4.2`
- Local timezone resolution: `flutter_timezone 4.1.1` + `timezone 0.10.1`
- Material 3, Provider, SharedPreferences and `intl 0.20.2`

## Work included in this revision

### Calendar display and navigation
- Month, Week and Agenda modes remain available.
- Month mode can be swiped left/right, with a soft animated transition.
- The month header now shows its **number within the active calendar** (for example, Month 03 of 12) above the month name. This appears on the calendar display only.
- Week mode uses the selected calendar's configured week start and day-count (1–14 days) rather than assuming a Monday-first Gregorian week.
- Week mode can be swiped by one configured calendar week; Day mode can be swiped one day at a time.
- Day mode contains a 24-hour timeline. Appointment cards show their start/end time, can be tapped to open details, and all-day appointments are displayed separately above the timeline.

### Events and appointments
- Events retain their notes, calendar, color and date.
- Added editable appointment duration (15 minutes through 3 hours).
- Corrected the all-day flag so a midnight timed appointment is no longer automatically treated as all-day in newly saved events. Legacy `00:00` records retain the old all-day interpretation when no flag exists.
- Event detail, day timeline, week summary and agenda show the appointment time range.
- Updating or deleting an event updates/cancels its pending reminder.

### Reminders and audible alerts
- Added event reminders at event time, 5/10/15/30 minutes, 1 hour or 1 day before.
- Reminder times use the device's IANA timezone, including daylight-saving transitions.
- Android notification permission is checked correctly on Android 12 and earlier as well as Android 13+.
- Android 14+ exact-alarm access is requested once when available; if it is declined, the app schedules an inexact reminder instead of silently dropping it.
- Added Android reboot receivers so scheduled reminders can be restored after restart.
- Created a new sound-enabled notification channel and a dedicated small notification icon. The Settings test-alert action sends an audible test notification.
- Existing saved events are rescheduled when the app loads. Removing a calendar or resetting data cancels its reminders.

### English and French
- Language is selected in **Settings → Experience → Language** and is saved across restarts.
- Added Flutter's English/French Material localization delegates and locale-aware date formatting.
- Expanded French translations across navigation, settings, calendar views, event creation, reminders, date tools, calendar creation and the introductory tour.
- User-entered calendar names, month names, weekday names and event titles are intentionally preserved exactly as entered.

### Existing unique features preserved
- Independent month lengths and names.
- Custom weekday names and week lengths.
- Configurable year start, year numbering and leap-year rules.
- Gregorian, Ethiopian and Biblical calendar support.
- Dual-calendar date comparison and offset calculator.
- Existing calendar creation/editing workflow and Christian tools.

## Build on Windows with Flutter 3.47.5

1. Extract the ZIP.
2. Open the `universal_calendar` folder in VS Code.
3. Confirm `flutter --version` reports Flutter 3.47.5.
4. Run `flutter pub get`.
5. Run `dart format lib`.
6. Run `flutter analyze` and resolve any SDK/environment-specific diagnostics.
7. Run `flutter test`.
8. Connect an Android device and run `flutter run`.
9. Test a reminder set 2–3 minutes ahead, test an event update/delete, restart the phone, and verify the reminder still arrives with sound.
10. Build with `flutter build apk --release` after the runtime checks pass.

## Verification status — important

This editing environment does **not** contain the Flutter SDK, Dart SDK or Android SDK. I therefore could not run `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, an APK build or physical-device notification tests. I did perform source-level delimiter checks, validate the Android manifest XML and `pubspec.yaml`, check the localization map for duplicate keys, and inspect the notification scheduling, event persistence and navigation paths. The added `test/calendar_models_test.dart` covers event serialization/migration and custom-week offset behavior, but those tests also still need to be executed with Flutter. This is not a substitute for a real Flutter build and device test, so I am not claiming a verified zero-error APK.
