# Universal Calendar

Universal Calendar is a Flutter calendar workspace built around user-defined calendar systems rather than a Gregorian-only calendar. It retains Gregorian, Ethiopian, Biblical and user-created calendars, dual-calendar comparison, custom month and weekday structures, date equivalents, offset calculations and the existing Christian utility screens.

## Target environment

- Target Flutter installation: **Flutter 3.47.5**
- Dart constraint: `>=3.4.0 <4.0.0`
- Android notifications: `flutter_local_notifications 19.4.2`
- Local timezone resolution: `flutter_timezone 4.1.1` + `timezone 0.10.1`
- Material 3, Provider, SharedPreferences and `intl 0.20.2`
- PDF generation: `pdf ^3.11.0` + `printing ^5.13.0`
- File saving for PDF export: `path_provider ^2.1.0`
- Pinned for compatibility: `image 4.5.4` + `archive 4.0.7` (see *Dependency compatibility fix* below)

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

### PDF export
- New **Export PDF** entry in the navigation drawer opens a dedicated export page.
- The export page lets the user pick which calendar to export, set a start/end month and year range, and toggle whether events, special days and a cover page are included.
- The generated PDF is typeset directly from the selected calendar's own month names, weekday names, week length and month lengths — not from a Gregorian template.
- Events and special days are drawn on the month grid (bold/special-colored day numbers) and listed below the grid, with a `+ N more events` overflow line.
- The finished PDF is saved to the app's documents directory as `<CalendarName>_calendar.pdf`, with a confirmation snackbar showing the full path.

### Error fixes in this revision
- **Missing `pdf_export_page.dart`** — the drawer referenced `PdfExportPage` but the file did not exist, so the project did not compile. The page has been created.
- **`PdfColor.withOpacity` does not exist** — the `pdf` package's `PdfColor` has no `withOpacity` (that is a Flutter `Color` method). The faded empty-day dot in the month grid now uses a pre-computed fainter hex color instead.
- **`path_provider` added as a direct dependency** — the export page imports it directly; it was previously only a transitive dependency.
- **`flutter analyze` is clean** — remaining `use_build_context_synchronously`, `prefer_function_declarations_over_variables`, `unnecessary_this`, deprecated `RadioListTile.groupValue`/`onChanged` (replaced with the modern `RadioGroup` widget) and deprecated `SwitchListTile.activeColor` diagnostics were resolved.

### Dependency compatibility fix
- `image 4.11.0` called `ZLibDecoder().decodeLazy()`, which does not exist in `archive 4.0.9`. This made the entire test suite fail to compile (the error surfaced through `pdf`/`printing`, which pull in `image` and `archive` transitively).
- `image` is pinned to **4.5.4** and `archive` to **4.0.7** in `pubspec.yaml` to keep both packages on a mutually compatible version.

### Test layout fix caught by the test suite
- The first-launch language picker screen used a fixed-height `Column` with `Spacer` widgets, which overflowed by ~23px on small viewports (the "language picker is shown on first launch" test caught a `RenderFlex overflow` assertion).
- The screen now wraps its content in a `SingleChildScrollView` sized by a `LayoutBuilder` so it scrolls on small screens while remaining vertically centered on larger ones.

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
