import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/navigation_provider.dart';
import '../l10n/tr.dart';
import 'calendar_explainer_page.dart';
import 'christian_tools_page.dart';
import 'create_calendar_page.dart';
import 'equivalents_page.dart';
import 'pdf_export_page.dart';
import 'agenda_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final nav = Provider.of<NavigationProvider>(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.calendar_month,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'Universal Calendar'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  Text(
                    '${calendarProvider.calendars.length} '
                    '${calendarProvider.calendars.length == 1 ? "calendar" : "calendars"}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Primary views ──────────────────────────────────────
            _drawerTile(context, Icons.home, tr(context, 'Home'), 0,
                nav.currentIndex, () => nav.setIndex(0)),

            _drawerTile(
              context,
              Icons.event_note_outlined,
              tr(context, 'Agenda'),
              -1,
              nav.currentIndex,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgendaPage()),
                );
              },
            ),

            _drawerTile(context, Icons.calendar_month, tr(context, 'Calendars'),
                1, nav.currentIndex, () => nav.setIndex(1)),

            // ── Actions ────────────────────────────────────────────
            _drawerTile(context, Icons.add, tr(context, 'Create Calendar'), -1,
                nav.currentIndex, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCalendarPage()),
              );
            }),

            _drawerTile(context, Icons.swap_horiz,
                tr(context, 'Find Equivalents'), -1, nav.currentIndex, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EquivalentsPage()),
              );
            }),

            _drawerTile(context, Icons.picture_as_pdf,
                tr(context, 'Export PDF'), -1, nav.currentIndex, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfExportPage()),
              );
            }),

            _drawerTile(context, Icons.auto_awesome,
                tr(context, 'Christian Tools'), -1, nav.currentIndex, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChristianToolsPage()),
              );
            }),

            _drawerTile(context, Icons.menu_book_outlined,
                tr(context, 'Calendar Guide'), -1, nav.currentIndex, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CalendarExplainerPage()),
              );
            }),

            const Divider(),

            // ── Settings & About ───────────────────────────────────
            _drawerTile(context, Icons.settings, tr(context, 'Settings'), 2,
                nav.currentIndex, () => nav.setIndex(2)),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(tr(context, 'About')),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String title,
    int index,
    int currentIndex,
    VoidCallback onTap,
  ) {
    final isSelected = index == currentIndex && index >= 0;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      tileColor: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        onTap();
        if (index >= 0 && Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Universal Calendar')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 3.0'),
            const SizedBox(height: 8),
            Text(tr(context,
                'A fully customizable calendar supporting Gregorian, Ethiopian, Biblical, and user-defined calendars.')),
            const SizedBox(height: 8),
            Text(tr(context, '• Create custom calendar structures')),
            Text(tr(context, '• Add events with notes and colors')),
            Text(tr(context, '• Find date equivalents across calendars')),
            Text(tr(context, '• Dual-calendar display')),
            Text(tr(context, '• Christian tools for daily devotion')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Close')),
          ),
        ],
      ),
    );
  }
}