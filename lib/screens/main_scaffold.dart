import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/notification_service.dart';
import '../l10n/tr.dart';
import 'app_drawer.dart';
import 'calendars_screen.dart';
import 'christian_tools_page.dart';
import 'event_detail_page.dart';
import 'event_search_page.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pendingNotificationEventId.addListener(_onNotificationTapped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFirstUseTour();
      _handleNotificationLaunch();
      _cancelRecentlyFiredReminders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pendingNotificationEventId.removeListener(_onNotificationTapped);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Covers the full-screen-intent case: the app is brought to front
      // without any notification tap, so onDidReceiveNotificationResponse
      // never fires. Cancelling on resume means the rings stop the moment
      // the user sees the app.
      _cancelRecentlyFiredReminders();
    }
  }

  /// Cancels every pending ring for any event whose reminder fired in the
  /// past 5 minutes. Skips recurring events (their scheduled notification
  /// represents the whole series — cancelling it would stop future days).
  Future<void> _cancelRecentlyFiredReminders() async {
    if (!mounted) return;
    final provider = context.read<CalendarProvider>();
    final now = DateTime.now();

    for (final event in provider.events) {
      if (!event.escalatingReminder) continue;
      if (event.repeatMode != 'once') continue;
      final minutes = event.reminderMinutesBefore;
      if (minutes == null) continue;

      try {
        final parts = event.date.split('-').map(int.parse).toList();
        final timeParts = event.time.split(':').map(int.parse).toList();
        if (parts.length != 3 || timeParts.length < 2) continue;

        final eventTime = DateTime(
            parts[0], parts[1], parts[2], timeParts[0], timeParts[1]);
        final reminderTime = eventTime.subtract(Duration(minutes: minutes));
        final since = now.difference(reminderTime);

        if (since.inSeconds >= 0 && since.inMinutes < 5) {
          await CalendarNotificationService.cancelEvent(event.id);
        }
      } catch (_) {}
    }
  }

  void _onNotificationTapped() {
    _handleNotificationLaunch();
  }

  void _handleNotificationLaunch() {
    final eventId = pendingNotificationEventId.value;
    if (eventId == null) return;
    pendingNotificationEventId.value = null;

    // Cancel any pending escalation rings for this event so the app
    // doesn't keep ringing after the user opens the event.
    unawaited(CalendarNotificationService.cancelEvent(eventId));

    final provider = context.read<CalendarProvider>();
    final event = provider.findEventById(eventId);
    if (event == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
    );
  }

  Future<void> showFirstUseTour({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!force && prefs.getBool('calendar_tour_seen') == true) return;

    var page = 0;
    final tour = [
      (
        tr(context, 'Welcome to Universal Calendar'),
        tr(context,
            'A calendar for every reckoning — Gregorian, Ethiopian, Biblical, Islamic, Julian, and your own designs.'),
        Icons.auto_awesome,
      ),
      (
        tr(context, 'Your calendars, together'),
        tr(context,
            'Switch between calendars and compare dates without losing your place — the day you selected stays synced across every calendar.'),
        Icons.calendar_month,
      ),
      (
        tr(context, 'Build a calendar your way'),
        tr(context,
            'Pick from templates, name your days and months, set month lengths, leap-year rules, and year numbering.'),
        Icons.tune,
      ),
      (
        tr(context, 'Biblical time is built in'),
        tr(context,
            'The day view can show biblical hours. Set your sunrise hour (6 or 7 AM) in Settings to align the 1st Hour with dawn.'),
        Icons.wb_twilight,
      ),
      (
        tr(context, 'Never miss a reminder'),
        tr(context,
            'Grant notification permission and each event can ring with sound and vibration. Tap "Test notification sound" in Settings to verify.'),
        Icons.notifications_active,
      ),
      (
        tr(context, 'Your data is yours'),
        tr(context,
            'Backup as JSON, export to .ics, or duplicate a calendar — from Settings or the Calendars screen. Import into Google or Apple Calendar any time.'),
        Icons.cloud_download,
      ),
    ];
    const totalPages = 6;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 34,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    tour[page].$3,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  tour[page].$1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  tour[page].$2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == page
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (page > 0)
                      TextButton(
                        onPressed: () => update(() => page--),
                        child: Text(tr(context, 'Back')),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          await prefs.setBool('calendar_tour_seen', true);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Text(tr(context, 'Skip tour')),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        if (page < totalPages - 1) {
                          update(() => page++);
                        } else {
                          await prefs.setBool('calendar_tour_seen', true);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      },
                      child: Text(
                        page == totalPages - 1
                            ? tr(context, 'Get started')
                            : tr(context, 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) await prefs.setBool('calendar_tour_seen', true);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) => Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(tr(context, 'Universal Calendar')),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventSearchPage()),
              ),
              tooltip: tr(context, 'Search events'),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChristianToolsPage()),
              ),
              tooltip: tr(context, 'Christian Tools'),
            ),
          ],
        ),
        body: IndexedStack(
          index: navProvider.currentIndex,
          children: const [
            HomeScreen(),
            CalendarsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}