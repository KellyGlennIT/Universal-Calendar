import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'providers/locale_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/christian_tools_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/create_calendar_page.dart';
import 'screens/equivalents_page.dart';
import 'screens/offset_calculator_page.dart';
import 'screens/event_detail_page.dart';
import 'screens/add_event_page.dart';
import 'screens/event_search_page.dart';
import 'screens/christian_tools_page.dart';
import 'screens/prayer_requests_page.dart';
import 'screens/bible_verse_page.dart';
import 'screens/fasting_tracker_page.dart';
import 'screens/gratitude_journal_page.dart';
import 'screens/prayer_timer_page.dart';
import 'screens/scripture_memory_page.dart';
import 'screens/calendar_explainer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await CalendarNotificationService.initialize();
  } catch (error) {
    debugPrint('Notification initialization failed: $error');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ChristianToolsProvider()),
      ],
      child: const UniversalCalendarApp(),
    ),
  );
}

class UniversalCalendarApp extends StatelessWidget {
  const UniversalCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watching LocaleProvider rebuilds the entire app on language change —
    // this is what makes instant English ↔ French switching work everywhere.
    final localeProvider = context.watch<LocaleProvider>();
    Intl.defaultLocale = localeProvider.locale.languageCode;

    return MaterialApp(
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: localeProvider.languageCode == 'fr'
          ? 'Calendrier universel'
          : 'Universal Calendar',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: !localeProvider.isLoaded
          ? const SplashScreen()
          : !localeProvider.hasSelectedLanguage
              ? const LanguageSelectionScreen()
              : const MainScaffold(),
      routes: {
        '/create_calendar': (context) => const CreateCalendarPage(),
        '/equivalents': (context) => const EquivalentsPage(),
        '/offset_calculator': (context) => const OffsetCalculatorPage(),
        '/event_detail': (context) => const EventDetailPage(),
        '/add_event': (context) => const AddEventPage(),
        '/event_search': (context) => const EventSearchPage(),
        '/christian_tools': (context) => const ChristianToolsPage(),
        '/prayer_requests': (context) => const PrayerRequestsPage(),
        '/bible_verse': (context) => const BibleVersePage(),
        '/fasting_tracker': (context) => const FastingTrackerPage(),
        '/gratitude_journal': (context) => const GratitudeJournalPage(),
        '/prayer_timer': (context) => const PrayerTimerPage(),
        '/scripture_memory': (context) => const ScriptureMemoryPage(),
        '/calendar_explainer': (context) => const CalendarExplainerPage(),
      },
    );
  }
}