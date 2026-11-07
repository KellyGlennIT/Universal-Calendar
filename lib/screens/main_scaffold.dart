import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../providers/navigation_provider.dart';
import '../l10n/tr.dart';
import 'app_drawer.dart';
import 'calendars_screen.dart';
import 'christian_tools_page.dart';
import 'event_search_page.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFirstUseTour();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
            'Choose an alarm when saving an event. Notifications and precise timing are requested only when you need them; test a tone in Settings.'),
        Icons.notifications_active,
      ),
      (
        tr(context, 'Your data is yours'),
        tr(context,
            'Back up as JSON or duplicate a calendar — from Settings or the Calendars screen.'),
        Icons.cloud_download,
      ),
    ];
    const totalPages = 6;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
