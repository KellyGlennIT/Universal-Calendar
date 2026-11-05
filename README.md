# Universal Calendar

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.4.0%20%3C4.0.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Analyze](https://img.shields.io/badge/flutter_analyze-clean-brightgreen)](#verification-status)
[![Tests](https://img.shields.io/badge/flutter_test-62%2F62%20passing-brightgreen)](#verification-status)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#license)

**Universal Calendar** is a Flutter calendar workspace built around *user-defined calendar systems* rather than a Gregorian-only model. It ships with Gregorian, Ethiopian and Biblical (Hebrew) calendars, lets users create entirely custom calendar structures, and layers a full scheduling suite on top — events, reminders, dual-calendar comparison, date tooling, PDF export and Christian devotional tools — in English and French.

---

## Table of Contents

- [Why Universal Calendar](#why-universal-calendar)
- [Features](#features)
  - [Custom calendar systems](#custom-calendar-systems)
  - [Calendar display and navigation](#calendar-display-and-navigation)
  - [Events and appointments](#events-and-appointments)
  - [Reminders and audible alerts](#reminders-and-audible-alerts)
  - [PDF export](#pdf-export)
  - [English and French](#english-and-french)
  - [Christian tools](#christian-tools)
- [Screenshots](#screenshots)
- [Project structure](#project-structure)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Build for release](#build-for-release)
- [Testing](#testing)
- [Day view performance](#day-view-performance)
- [Data storage and privacy](#data-storage-and-privacy)
- [Recent changes](#recent-changes)
- [Verification status](#verification-status)
- [License](#license)

---

## Why Universal Calendar

Most calendar apps hard-code Gregorian assumptions — 12 months of fixed lengths, 7-day weeks, Monday-first ordering. Universal Calendar treats the calendar itself as *data*:

- A calendar can have **any number of months** (1–99) with **independent names and lengths**.
- A week can be **1 to 14 days long**, with fully custom weekday names.
- The **year start** (month + day), year numbering offset and **leap-year rule** (Gregorian, every-4, custom cycle pattern, or none) are all configurable.
- Conversions between any two installed calendars — Gregorian, Ethiopian, Biblical, or one the user invented — happen through a shared date engine.

This makes it suitable for liturgical planning, cultural/religious calendar observation, alternate-calendar experimentation, and date-tooling workflows that standard apps cannot express.

---

## Features

### Custom calendar systems

- **Presets included:** Gregorian, Ethiopian, Biblical (Hebrew) — plus a blank custom template.
- **Step-by-step creator** for building a calendar: naming, color/emoji selection, month structure, weekday structure, year-start, leap rules and display formats (24h/12h, date format, timezone).
- **Full editing workflow** for existing calendars, including special-day management.
- **Year offset with a live preview** — the offset can be stepped (long-press steps by 100) or typed directly, and a preview shows the resulting year for three sample dates *before* saving.
- Independent month lengths and names; custom weekday names and week lengths; configurable year start, year numbering and leap-year rules.
- **Dual-calendar comparison** — see how a date in one calendar maps to another, side by side.
- **Offset calculator** — count days between dates across differing calendar structures.
- **Date equivalents** lookup — find what a given date corresponds to in every installed calendar.

### Calendar display and navigation

- **Month, Week and Agenda** modes.
- Month mode supports horizontal swiping with a soft animated transition.
- **Day view** is built on a single `CustomScrollView` (one scrollable, no nested scroll views): a gradient hero, a pinned day strip and a lazily-built agenda. See [Day view performance](#day-view-performance).
- The month header shows its **number within the active calendar** (e.g. *Month 03 of 12*) above the month name — this respects the active calendar, not a fixed Gregorian index.
- Week mode uses the selected calendar's **configured week start and day-count (1–14 days)** rather than assuming a Monday-first Gregorian week.
- Week mode swipes by one configured calendar week; Day mode swipes one day at a time.
- **Day mode** shows only the hours that actually hold appointments — a schedule list rather than an empty 24-hour grid. Appointment cards show their start/end time, can be tapped to open details, and all-day appointments display separately above the timeline.
- The day strip is a lazily-built horizontal list that stays centred on the selected day: swiping the page, tapping *Today*, or tapping a chip scrolls the strip, and a fling snaps it back to the selection.

### Events and appointments

- Events retain notes, calendar, color and date.
- **Editable appointment duration** (15 minutes through 3 hours).
- Corrected the all-day flag so a midnight timed appointment is no longer automatically treated as all-day in newly saved events. Legacy `00:00` records retain the old all-day interpretation when no flag exists (backwards-compatible migration).
- Event detail, day timeline, week summary and agenda all show the appointment time range.
- Updating or deleting an event updates/cancels its pending reminder.
- Full-text **event search** across all calendars.

### Reminders and audible alerts

- Reminders at event time, **5/10/15/30 minutes, 1 hour or 1 day** before.
- Reminder times use the device's **IANA timezone**, including daylight-saving transitions.
- Android notification permission is checked correctly on Android 12 and earlier as well as Android 13+.
- Android 14+ **exact-alarm access** is requested once when available; if declined, the app schedules an inexact reminder instead of silently dropping it.
- **Android reboot receivers** restore scheduled reminders after device restart.
- A dedicated **sound-enabled notification channel** and small notification icon. The Settings *test-alert* action sends an audible test notification.
- Existing saved events are rescheduled when the app loads. Removing a calendar or resetting data cancels its reminders.
- A first-run **notification permission screen** explains why the app needs the permission before requesting it.

### PDF export

- New **Export PDF** entry in the navigation drawer opens a dedicated export page.
- The export page lets the user pick which calendar to export, set a start/end month and year range, and toggle whether events, special days and a cover page are included.
- The generated PDF is typeset directly from the selected calendar's **own month names, weekday names, week length and month lengths** — not from a Gregorian template.
- Events and special days are drawn on the month grid (bold/special-colored day numbers) and listed below the grid, with a `+ N more events` overflow line.
- The finished PDF is saved to the app's documents directory as `<CalendarName>_calendar.pdf`, with a confirmation snackbar showing the full path.
- The export page also supports **ICS (calendar) and CSV export** via the existing `ExportService`.

### English and French

- Language is selected at **first launch** (full-screen picker) or later in **Settings → Experience → Language**, and persists across restarts.
- Flutter's English/French Material localization delegates and locale-aware date formatting.
- Expanded French translations across navigation, settings, calendar views, event creation, reminders, date tools, calendar creation and the introductory tour.
- User-entered calendar names, month names, weekday names and event titles are intentionally **preserved exactly as entered** (never machine-translated).

### Christian tools

A dedicated suite of devotional utilities:

- **Bible verse** of the day.
- **Scripture memory** tracker.
- **Prayer requests** log.
- **Prayer timer**.
- **Gratitude journal**.
- **Fasting tracker**.

---

## Screenshots

> *Screenshots pending — placeholder section.*

| Month view | Day timeline | Create calendar | PDF export |
|---|---|---|---|
| _TBD_ | _TBD_ | _TBD_ | _TBD_ |

---

## Project structure

```
universal_calendar/
├── lib/
│   ├── main.dart                     # App entry, routes, providers
│   ├── models/                       # CalendarModel, CalendarEvent, SpecialDay, …
│   ├── providers/                    # State (calendar, locale, navigation, tools)
│   ├── screens/                      # All UI screens (home, calendar, settings, …)
│   ├── services/                     # Notifications, PDF export, ICS/CSV export
│   ├── theme/                        # App-wide Material 3 theme
│   ├── utils/                        # Calendar math, presets, formatters, dialogs
│   │   └── notification_sounds.dart  # Alert-tone catalogue + playback helpers
│   └── l10n/                         # Localization (tr() helper, French strings)
├── assets/
│   ├── fonts/                        # Noto Sans Regular / Bold
│   └── sounds/                       # Bundled notification tones (.wav)
├── test/
│   ├── calendar_math_test.dart       # Date-engine reference cases (Julian, Hebrew, French…)
│   ├── calendar_models_test.dart     # Models, calendars, provider, localization
│   ├── pdf_render_test.dart          # PDF generation smoke test
│   └── widget_test.dart              # Smoke test
├── tools/
│   └── generate_notification_tones.ps1  # Regenerates assets/sounds/*.wav
├── android/ · ios/ · linux/ · macos/ · web/ · windows/
└── pubspec.yaml
```

---

## Requirements

| Component | Version |
|---|---|
| Flutter | **3.47.5** (target) |
| Dart | `>=3.4.0 <4.0.0` |
| Android | Android 12+ tested; 13+/14+ permission paths implemented |
| Notifications | `flutter_local_notifications 19.4.2` |
| Timezone | `flutter_timezone 4.1.1` + `timezone 0.10.1` |
| UI / state | Material 3, `provider ^6.0.0`, `shared_preferences`, `intl 0.20.2` |
| PDF | `pdf ^3.11.0` + `printing ^5.13.0` |
| File saving / sharing | `path_provider ^2.1.0`, `share_plus ^12.0.0` |
| Bundled assets | Notification tones (`assets/sounds/*.wav`), Noto Sans font |
| Compatibility pins | `image 4.5.4` + `archive 4.0.7` — see [Recent changes](#recent-changes) |

---

## Getting started

### 1. Prerequisites

- Flutter SDK **3.47.5** installed and on your `PATH`. Verify:

  ```sh
  flutter --version
  ```

  The output should report Flutter 3.47.5 and a Dart SDK in the `>=3.4.0 <4.0.0` range.

- An Android device or emulator connected (for `flutter run` / release testing). Desktop and web targets are present in the project but the notification features are Android-specific.

### 2. Install dependencies

```sh
cd universal_calendar
flutter pub get
```

### 3. Format and analyze

```sh
dart format lib
flutter analyze
```

`flutter analyze` currently reports **no issues** — keep it that way before committing.

### 4. Run the tests

```sh
flutter test
```

All **62 tests** currently pass.

### 5. Run the app

```sh
flutter run
```

The app starts with a splash screen, then either the **first-launch language picker** (English / Français) or the home screen, depending on whether a language has already been chosen.

---

## Build for release

The app targets **Android phones** first; desktop and web targets compile but the notification features are Android-specific.

```sh
# Split per-ABI APKs are smaller to transfer and install by hand
flutter build apk --release --split-per-abi
```

The release APKs are produced in `build/app/outputs/flutter-apk/`:

| File | Device |
|---|---|
| `app-arm64-v8a-release.apk` | Almost every phone from ~2017 onward — **use this one** |
| `app-armeabi-v7a-release.apk` | Older 32-bit devices |
| `app-x86_64-release.apk` | Emulators / x86 tablets |

For a single universal APK instead, run `flutter build apk --release` (larger, works everywhere).

To install on a connected phone:

```sh
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

or copy the APK to the phone and open it (allow *Install unknown apps* for the file manager).

---

## Testing

The test suite lives in `test/` (62 tests):

- **`calendar_math_test.dart`** — covers:
  - Rata Die epoch and round-trips.
  - Julian/Gregorian conversion against reference tables (1582 reform, 13-day skew).
  - Hebrew (Rosh Hashanah, Yom Kippur, Hanukkah, Pesach) with month numbering kept inside 1–13.
  - French Republican epoch and Hijri month lengths.
  - Week-start offsets and weekday headers for Gregorian, Sunday-first, Ethiopian and a renamed start (`Shabbat`).
- **`calendar_models_test.dart`** — covers:
  - Event serialization, legacy migration and reminder/all-day/duration defaults.
  - Custom week structure (e.g. a 5-day week start offset).
  - Leap-year rules (`every4`, `gregorian`, `custom` cycle, `none`).
  - Ethiopian calendar month lengths, Pagume and New Year date math.
  - Hebrew (Biblical) month ordering and full-year conversion validity.
  - `LocaleProvider` lifecycle (fresh install, saved French, set/persist, unsupported language rejection).
  - `CalendarProvider` defaults, reset-all-data and event lookup.
  - First-launch language-picker rendering (catches layout overflow regressions).
  - `tr()` localization lookups and fallback behavior.
- **`pdf_render_test.dart`** — renders a PDF and checks it is produced.
- **`widget_test.dart`** — basic smoke test.

Run with `flutter test`. A clean run prints `All tests passed!`.

> **Note:** Two harmless `LateInitializationError` messages for the notification plugin instance may appear in the test log when a test cancels reminders without initializing the plugin. This is expected in a test environment where the platform channel isn't mocked, and does not affect test results or the app at runtime.

---

## Data storage and privacy

- All calendars, events, language choice and app settings are stored **locally** on the device using `SharedPreferences` (JSON-serialized).
- No network calls, analytics or telemetry.
- Exported PDF / ICS / CSV files are written to the app's **documents directory** only — nothing is uploaded.
- **Reset All Data** (in Settings) wipes calendars, events and preferences back to the three built-in default calendars and cancels all pending reminders.

---

## Day view performance

The day view is tuned for mid-range phones:

- **One scrollable.** The whole screen is a single `CustomScrollView` — hero, pinned day strip and agenda are slivers of it. There is no `SingleChildScrollView` wrapping a `ListView` (the classic nested-scroll jank pattern) and no `shrinkWrap` list inside a scroll view.
- **Lazy agenda.** Rows are built by `SliverList.builder`, so only visible appointments exist as widgets. Hours without appointments are not rendered at all.
- **Indexed lookups.** Events are bucketed by date once and reused until the event list or selected calendar changes, so changing days no longer re-scans the whole event store on every rebuild.
- **Fixed-extent strip.** The day strip uses `itemExtent`, so Flutter never has to measure tiles while scrolling, and only the visible chips are built.
- **Single locale subscription.** The screen watches `LocaleProvider` once (it previously subscribed twice, causing a redundant rebuild path).

---

## Recent changes

### PDF export
- New **Export PDF** entry in the navigation drawer opens a dedicated export page.
- The export page lets the user pick which calendar to export, set a start/end month and year range, and toggle whether events, special days and a cover page are included.
- The generated PDF is typeset directly from the selected calendar's own month names, weekday names, week length and month lengths — not from a Gregorian template.
- Events and special days are drawn on the month grid (bold/special-colored day numbers) and listed below the grid, with a `+ N more events` overflow line.
- The finished PDF is saved to the app's documents directory as `<CalendarName>_calendar.pdf`, with a confirmation snackbar showing the full path.

### Day view and editing
- **Day view rewritten** around one `CustomScrollView` with a gradient hero, a pinned day strip and a lazily-built agenda (see [Day view performance](#day-view-performance)).
- **Day strip stays in sync** — swiping, *Today*, and chip taps all scroll the strip, and a fling snaps it back onto the selected day.
- **Year offset is easier to set** — tap the number to type a value, or long-press the ± buttons to step by 100 (useful for the French Republican calendar at −1791). The live three-date preview updates immediately.
- **Hebrew month numbering fixed** — month numbers now stay within 1–13 in leap years (Elul was reported as 14) and week headers line up with the grid for Sunday-first, Ethiopian and renamed week starts.

### Error fixes
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

---

## Verification status

The following commands were run in this environment and are confirmed passing:

| Command | Result |
|---|---|
| `flutter pub get` | ✅ Dependencies resolve with the pinned `image 4.5.4` / `archive 4.0.7` pair. |
| `flutter analyze` | ✅ **No issues found** — zero errors, warnings and infos. |
| `flutter test` | ✅ **All 62 tests pass.** |

**Not yet verified in this environment:**

- A physical Android device run, real notification delivery, audible reminder behavior, reboot-receiver restoration and the exact-alarm permission flow require a device/emulator and were not exercised here.
- An APK release build (`flutter build apk --release`) was not performed. Run it after the on-device checks pass.
- Scroll smoothness was reviewed in code (single scrollable, lazy slivers, fixed-extent strip, indexed event lookup) but frame timings on a physical phone were not profiled here — use `flutter run --profile` and DevTools to confirm on your device.

---

## License

License

Universal Calendar is free and open-source software licensed under the GNU General Public License v3.0 (GPL-3.0).

You are free to use, study, modify, and distribute this software under the terms of the license.

See the "LICENSE" (LICENSE) file for the complete license terms.
