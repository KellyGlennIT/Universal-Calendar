import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../services/pdf_export_service.dart';
import '../l10n/tr.dart';

/// Lets the user pick a calendar, a month range and what to include,
/// then generates and saves/shares a beautifully typeset PDF.
class PdfExportPage extends StatefulWidget {
  const PdfExportPage({super.key});

  @override
  State<PdfExportPage> createState() => _PdfExportPageState();
}

class _PdfExportPageState extends State<PdfExportPage> {
  String? _selectedCalendarId;
  bool _includeEvents = true;
  bool _includeSpecialDays = true;
  bool _includeCoverPage = true;
  bool _generating = false;

  late int _startYear;
  late int _startMonth;
  late int _endYear;
  late int _endMonth;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startYear = now.year;
    _startMonth = now.month;
    _endYear = now.year;
    _endMonth = now.month;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default to the first available calendar once the provider is ready.
    final provider = Provider.of<CalendarProvider>(context);
    if (_selectedCalendarId == null && provider.calendars.isNotEmpty) {
      _selectedCalendarId = provider.calendars.first.id;
    }
  }

  Future<void> _pickYear({required bool isStart}) async {
    final initial = isStart ? _startYear : _endYear;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        var value = initial;
        return AlertDialog(
          title: Text(tr(context, isStart ? 'Start Year' : 'End Year')),
          content: StatefulBuilder(
            builder: (context, setState) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => value--),
                ),
                Text('$value',
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => value++),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(context, 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: Text(tr(context, 'OK')),
            ),
          ],
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startYear = picked;
          if (_endYear < _startYear) _endYear = _startYear;
        } else {
          _endYear = picked;
          if (_endYear < _startYear) _startYear = _endYear;
        }
      });
    }
  }

  Future<void> _export() async {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final calendar = provider.calendars.firstWhere(
        (c) => c.id == _selectedCalendarId,
        orElse: () => provider.calendars.first);

    setState(() => _generating = true);
    try {
      final bytes = await PdfExportService.generateCalendarPdf(
        calendar: calendar,
        allEvents: provider.events,
        startYear: _startYear,
        startMonth: _startMonth,
        endYear: _endYear,
        endMonth: _endMonth,
        includeEvents: _includeEvents,
        includeSpecialDays: _includeSpecialDays,
        includeCoverPage: _includeCoverPage,
      );

      final dir = await getApplicationDocumentsDirectory();
      final safeName = calendar.name.replaceAll(RegExp(r'[^\w\- ]'), '').trim();
      final file = File(
          '${dir.path}/${safeName.isEmpty ? 'calendar' : safeName}_calendar.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final savedMsg = tr(context, 'PDF saved to ${file.path}');
      messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final failMsg = tr(context, 'Export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failMsg)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr(context, 'Export PDF'))),
      body: provider.calendars.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      tr(context,
                          'Create a calendar first to export it as a PDF.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Calendar picker ──────────────────────────────
                Text(tr(context, 'Calendar'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _selectedCalendarId,
                  onChanged: (v) => setState(() => _selectedCalendarId = v),
                  child: Column(
                    children: provider.calendars
                        .map((c) => RadioListTile<String>(
                              value: c.id,
                              title: Text('${c.emoji} ${c.name}'),
                            ))
                        .toList(),
                  ),
                ),
                const Divider(height: 32),

                // ── Month range ──────────────────────────────────
                Text(tr(context, 'Range'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _startMonth,
                        decoration:
                            const InputDecoration(labelText: 'From month'),
                        items: [
                          for (int m = 1; m <= 12; m++)
                            DropdownMenuItem(
                                value: m, child: Text(_monthNames[m - 1])),
                        ],
                        onChanged: (v) =>
                            setState(() => _startMonth = v ?? _startMonth),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickYear(isStart: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Year'),
                          child: Text('$_startYear'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _endMonth,
                        decoration:
                            const InputDecoration(labelText: 'To month'),
                        items: [
                          for (int m = 1; m <= 12; m++)
                            DropdownMenuItem(
                                value: m, child: Text(_monthNames[m - 1])),
                        ],
                        onChanged: (v) =>
                            setState(() => _endMonth = v ?? _endMonth),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickYear(isStart: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Year'),
                          child: Text('$_endYear'),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // ── Options ──────────────────────────────────────
                Text(tr(context, 'Include'),
                    style: Theme.of(context).textTheme.titleSmall),
                SwitchListTile(
                  title: Text(tr(context, 'Events')),
                  value: _includeEvents,
                  onChanged: (v) => setState(() => _includeEvents = v),
                ),
                SwitchListTile(
                  title: Text(tr(context, 'Special days')),
                  value: _includeSpecialDays,
                  onChanged: (v) => setState(() => _includeSpecialDays = v),
                ),
                SwitchListTile(
                  title: Text(tr(context, 'Cover page')),
                  value: _includeCoverPage,
                  onChanged: (v) => setState(() => _includeCoverPage = v),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _generating ? null : _export,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_generating
                      ? tr(context, 'Generating...')
                      : tr(context, 'Export PDF')),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _generating
                      ? null
                      : () async {
                          final provider = Provider.of<CalendarProvider>(
                              context,
                              listen: false);
                          final calendar = provider.calendars.firstWhere(
                              (c) => c.id == _selectedCalendarId,
                              orElse: () => provider.calendars.first);
                          final bytes =
                              await PdfExportService.generateCalendarPdf(
                            calendar: calendar,
                            allEvents: provider.events,
                            startYear: _startYear,
                            startMonth: _startMonth,
                            endYear: _endYear,
                            endMonth: _endMonth,
                            includeEvents: _includeEvents,
                            includeSpecialDays: _includeSpecialDays,
                            includeCoverPage: _includeCoverPage,
                          );
                          final dir = await getApplicationDocumentsDirectory();
                          final safeName = calendar.name
                              .replaceAll(RegExp(r'[^\w\- ]'), '')
                              .trim();
                          final file = File(
                              '${dir.path}/${safeName.isEmpty ? 'calendar' : safeName}_calendar.pdf');
                          await file.writeAsBytes(bytes);
                          if (!mounted) return;
                          final messenger = ScaffoldMessenger.of(this.context);
                          final savedMsg =
                              tr(this.context, 'PDF saved to ${file.path}');
                          messenger.showSnackBar(
                            SnackBar(content: Text(savedMsg)),
                          );
                        },
                  icon: const Icon(Icons.save_alt),
                  label: Text(tr(context, 'Save to device')),
                ),
              ],
            ),
    );
  }
}
