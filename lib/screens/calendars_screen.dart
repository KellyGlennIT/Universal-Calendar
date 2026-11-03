import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../services/export_service.dart';
import '../l10n/tr.dart';
import 'calendar_explainer_page.dart';
import 'create_calendar_page.dart';
import 'edit_calendar_page.dart';
import 'special_days_page.dart';

class CalendarsScreen extends StatelessWidget {
  const CalendarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(tr(context, 'Calendars')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: tr(context, 'Calendar Guide'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CalendarExplainerPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateCalendarPage()),
              ),
            ),
          ],
        ),
        body: provider.calendars.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(tr(context, 'No calendars yet'),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'Tap the + button to create one.'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.calendars.length,
                itemBuilder: (context, index) {
                  final cal = provider.calendars[index];
                  final eventCount = provider.events
                      .where((e) => e.calendarId == cal.id)
                      .length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            cal.color.withValues(alpha: 0.2),
                        child: Text(cal.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(cal.name),
                      subtitle: Text(
                        '${cal.daysPerWeek} ${tr(context, 'Days/week')}, '
                        '${cal.monthsPerYear} ${tr(context, 'months/year')}, '
                        '$eventCount ${tr(context, 'events')}',
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) =>
                            _handleMenu(context, provider, cal, value),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'export_ics',
                            child: Row(children: const [
                              Icon(Icons.file_download_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Export as .ics'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'export_csv',
                            child: Row(children: const [
                              Icon(Icons.table_view_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Export as CSV'),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'special_days',
                            child: Row(children: const [
                              Icon(Icons.star_outline, size: 20),
                              SizedBox(width: 12),
                              Text('Special Days'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(children: const [
                              Icon(Icons.copy_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Duplicate calendar'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: const [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: const [
                              Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditCalendarPage(calendar: cal)),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCalendarPage()),
          ),
          tooltip: tr(context, 'Create Calendar'),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    CalendarProvider provider,
    CalendarModel cal,
    String value,
  ) async {
    switch (value) {
      case 'export_ics':
        final ics = ExportService.generateIcs(
          calendar: cal,
          events: provider.eventsForCalendar(cal.id),
        );
        await Clipboard.setData(ClipboardData(text: ics));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(context, 'Exported to clipboard')),
            duration: const Duration(seconds: 3),
          ));
        }
        break;
      case 'export_csv':
        final csv =
            ExportService.generateCsv(provider.eventsForCalendar(cal.id));
        await Clipboard.setData(ClipboardData(text: csv));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(context, 'Exported to clipboard')),
            duration: const Duration(seconds: 3),
          ));
        }
        break;
      case 'special_days':
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpecialDaysPage(calendarId: cal.id),
            ),
          );
        }
        break;
      case 'duplicate':
        provider.duplicateCalendar(cal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(context, 'Calendar duplicated')),
            duration: const Duration(seconds: 2),
          ));
        }
        break;
      case 'edit':
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditCalendarPage(calendar: cal)),
          );
        }
        break;
      case 'delete':
        if (context.mounted) _confirmDelete(context, provider, cal.id);
        break;
    }
  }

  void _confirmDelete(
      BuildContext context, CalendarProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Delete Calendar')),
        content: Text(tr(context,
            'Are you sure you want to delete this calendar? All events will also be deleted.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              if (provider.calendars.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr(context,
                      'You must keep at least one calendar.')),
                ));
                return;
              }
              provider.deleteCalendar(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr(context, 'Delete')),
          ),
        ],
      ),
    );
  }
}