// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _Ev {
  final String title;
  final String? description;
  final DateTime? date;
  final String? time;
  const _Ev({required this.title, this.description, this.date, this.time});
}

enum _ExportMode { events, calendar }

enum _RangePreset { all, thisMonth, thisYear, custom }

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class PdfExportPage extends StatefulWidget {
  const PdfExportPage({super.key});

  @override
  State<PdfExportPage> createState() => _PdfExportPageState();
}

class _PdfExportPageState extends State<PdfExportPage> {
  // Shared
  _ExportMode _mode = _ExportMode.events;
  int _previewVersion = 0;

  // Events mode
  _RangePreset _preset = _RangePreset.all;
  DateTimeRange? _customRange;
  bool _includeDescription = true;
  bool _groupByMonth = true;

  // Calendar mode
  int _calendarYear = DateTime.now().year;
  bool _twoMonthsPerPage = true;
  bool _showEventDots = true;

  // ── DATA EXTRACTION (defensive) ────────────────────────────────────────
  List<_Ev> _extractEvents(CalendarProvider provider) {
    List<dynamic> raw = const [];
    try {
      final v = (provider as dynamic).events;
      if (v is List) raw = v;
    } catch (_) {}
    if (raw.isEmpty) {
      try {
        final v = (provider as dynamic).allEvents;
        if (v is List) raw = v;
      } catch (_) {}
    }
    final out = <_Ev>[];
    for (final e in raw) {
      try {
        out.add(_Ev(
          title: _titleOf(e),
          description: _descriptionOf(e),
          date: _dateOf(e),
          time: _timeOf(e),
        ));
      } catch (_) {}
    }
    return out;
  }

  String _titleOf(dynamic e) {
    try {
      final v = e.title;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    try {
      final v = e.name;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    return 'Untitled event';
  }

  String? _descriptionOf(dynamic e) {
    try {
      final v = e.description;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    try {
      final v = e.details;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    return null;
  }

  DateTime? _dateOf(dynamic e) {
    try {
      final v = e.date;
      if (v is DateTime) return v;
    } catch (_) {}
    try {
      final v = e.dateTime;
      if (v is DateTime) return v;
    } catch (_) {}
    try {
      final v = e.startDate;
      if (v is DateTime) return v;
    } catch (_) {}
    try {
      final v = e.start;
      if (v is DateTime) return v;
    } catch (_) {}
    return null;
  }

  String? _timeOf(dynamic e) {
    try {
      final v = e.time;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    final d = _dateOf(e);
    if (d != null && (d.hour != 0 || d.minute != 0)) {
      return DateFormat.Hm().format(d);
    }
    return null;
  }

  // ── EVENT FILTER ───────────────────────────────────────────────────────
  List<_Ev> _applyFilter(List<_Ev> all, DateTime now) {
    switch (_preset) {
      case _RangePreset.all:
        return all;
      case _RangePreset.thisMonth:
        return all
            .where((e) =>
                e.date != null &&
                e.date!.year == now.year &&
                e.date!.month == now.month)
            .toList();
      case _RangePreset.thisYear:
        return all
            .where((e) => e.date != null && e.date!.year == now.year)
            .toList();
      case _RangePreset.custom:
        final r = _customRange;
        if (r == null) return all;
        final start = DateTime(r.start.year, r.start.month, r.start.day);
        final end = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
        return all
            .where((e) =>
                e.date != null &&
                !e.date!.isBefore(start) &&
                !e.date!.isAfter(end))
            .toList();
    }
  }

  int _monthsCount(List<_Ev> events) {
    final set = <String>{};
    for (final e in events) {
      if (e.date != null) set.add('${e.date!.year}-${e.date!.month}');
    }
    return set.length;
  }

  String _rangeLabel(bool fr) {
    final now = DateTime.now();
    final fmt = DateFormat.yMMMMd(fr ? 'fr' : 'en');
    switch (_preset) {
      case _RangePreset.all:
        return fr ? 'Tous les événements' : 'All events';
      case _RangePreset.thisMonth:
        return fmt.format(DateTime(now.year, now.month, 1));
      case _RangePreset.thisYear:
        return '${now.year}';
      case _RangePreset.custom:
        if (_customRange == null) {
          return fr ? 'Plage personnalisée' : 'Custom range';
        }
        return '${fmt.format(_customRange!.start)} – ${fmt.format(_customRange!.end)}';
    }
  }

  Future<void> _pickRange(bool fr) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customRange,
      helpText: fr ? 'Sélectionner une plage' : 'Select a range',
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _preset = _RangePreset.custom;
        _previewVersion++;
      });
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final locale = localeProvider.locale.languageCode;
    final fr = locale == 'fr';

    final calendar = context.watch<CalendarProvider>();
    final all = _extractEvents(calendar);
    final now = DateTime.now();
    final filtered = _applyFilter(all, now)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return a.title.compareTo(b.title);
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });

    final rangeLabel = _rangeLabel(fr);

    final providerSnapshot = _ProviderSnapshot(
      events: calendar.events,
      selectedCalendar: calendar.selectedCalendar,
      secondaryCalendarId: calendar.secondaryCalendarId,
      calendars: calendar.calendars,
      selectedCalendarId: calendar.selectedCalendarId,
    );

    final previewKey = _mode == _ExportMode.events
        ? 'evt-${_preset.name}-${filtered.length}-'
            '$_includeDescription-$_groupByMonth-$_previewVersion'
        : 'cal-$_calendarYear-$_twoMonthsPerPage-$_showEventDots-'
            '${providerSnapshot.selectedCalendarId}-$_previewVersion';

    return Scaffold(
      appBar: AppBar(
        title: Text(fr ? 'Export PDF' : 'PDF Export'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final preview = _buildPreview(
            events: filtered,
            snapshot: providerSnapshot,
            locale: locale,
            rangeLabel: rangeLabel,
            fr: fr,
            previewKey: previewKey,
          );
          final options = _buildOptions(
            context: context,
            fr: fr,
            all: all,
            filtered: filtered,
            rangeLabel: rangeLabel,
            snapshot: providerSnapshot,
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: options,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: preview),
              ],
            );
          }

          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(
                      fr ? 'Options d\'export' : 'Export options',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _mode == _ExportMode.events
                          ? '${filtered.length} ${fr ? "événements" : "events"} · $rangeLabel'
                          : '$_calendarYear · ${_twoMonthsPerPage ? "2" : "1"} ${fr ? "mois/page" : "months/page"}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    children: [options],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }

  // ── PREVIEW ───────────────────────────────────────────────────────────
  Widget _buildPreview({
    required List<_Ev> events,
    required _ProviderSnapshot snapshot,
    required String locale,
    required String rangeLabel,
    required bool fr,
    required String previewKey,
  }) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface.withOpacity(0.35),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Icon(
                  _mode == _ExportMode.events
                      ? Icons.description_outlined
                      : Icons.calendar_month_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mode == _ExportMode.events
                        ? (fr ? 'Aperçu des événements' : 'Events preview')
                        : (fr
                            ? 'Aperçu du calendrier $_calendarYear'
                            : 'Calendar $_calendarYear preview'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
                IconButton(
                  tooltip: fr ? 'Partager le PDF' : 'Share PDF',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () async {
                    final bytes = _mode == _ExportMode.events
                        ? await _buildEventsPdf(
                            PdfPageFormat.a4, events, locale, rangeLabel)
                        : await _buildCalendarPdf(
                            PdfPageFormat.a4, snapshot, locale);
                    if (!mounted) return;
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'universal_calendar_'
                          '${_mode == _ExportMode.events ? "events" : "$_calendarYear"}.pdf',
                    );
                  },
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _mode == _ExportMode.events
                        ? '${events.length}'
                        : '12 ${fr ? "mois" : "mo"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PdfPreview(
                  key: ValueKey(previewKey),
                  build: (format) => _mode == _ExportMode.events
                      ? _buildEventsPdf(format, events, locale, rangeLabel)
                      : _buildCalendarPdf(format, snapshot, locale),
                  initialPageFormat: PdfPageFormat.a4,
                  canChangePageFormat: true,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  pdfFileName:
                      'universal_calendar_${_mode == _ExportMode.events ? "events" : _calendarYear}',
                  loadingWidget:
                      const Center(child: CircularProgressIndicator()),
                  onError: (ctx, err) => _errorWidget(fr, err),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget(bool fr, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              fr
                  ? 'Impossible de générer l\'aperçu'
                  : 'Could not generate preview',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('$error',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── OPTIONS PANEL ──────────────────────────────────────────────────────
  Widget _buildOptions({
    required BuildContext context,
    required bool fr,
    required List<_Ev> all,
    required List<_Ev> filtered,
    required String rangeLabel,
    required _ProviderSnapshot snapshot,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B0764),
                Color(0xFF6D28D9),
                Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                fr ? 'Créez un PDF élégant' : 'Craft an elegant PDF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fr
                    ? 'Choisissez d\'exporter vos événements ou le calendrier complet d\'une année, dans un document soigné.'
                    : 'Export your events, or the full year calendar, as a beautifully crafted document.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SegmentedButton<_ExportMode>(
          segments: [
            ButtonSegment(
              value: _ExportMode.events,
              label: Text(fr ? 'Événements' : 'Events',
                  style: const TextStyle(fontSize: 12.5)),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
            ),
            ButtonSegment(
              value: _ExportMode.calendar,
              label: Text(fr ? 'Calendrier' : 'Calendar',
                  style: const TextStyle(fontSize: 12.5)),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _previewVersion++;
          }),
        ),
        const SizedBox(height: 20),
        if (_mode == _ExportMode.events)
          _buildEventsOptions(context, fr, all, filtered, rangeLabel)
        else
          _buildCalendarOptions(context, fr, snapshot),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _previewVersion++),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(fr ? 'Actualiser l\'aperçu' : 'Refresh preview'),
        ),
        const SizedBox(height: 8),
        Text(
          fr
              ? 'Astuce : utilisez les boutons partager / imprimer dans l\'aperçu.'
              : 'Tip: use the share / print buttons inside the preview.',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEventsOptions(BuildContext context, bool fr, List<_Ev> all,
      List<_Ev> filtered, String rangeLabel) {
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(fr ? 'Plage de dates' : 'Date range', style: sectionStyle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip(fr ? 'Tout' : 'All', _RangePreset.all),
            _presetChip(fr ? 'Ce mois' : 'This month', _RangePreset.thisMonth),
            _presetChip(fr ? 'Cette année' : 'This year', _RangePreset.thisYear),
            _presetChip(fr ? 'Personnalisé' : 'Custom', _RangePreset.custom),
          ],
        ),
        if (_preset == _RangePreset.custom) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickRange(fr),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(
              _customRange == null
                  ? (fr ? 'Choisir une plage' : 'Choose a range')
                  : '${DateFormat.yMMMd(fr ? "fr" : "en").format(_customRange!.start)} → '
                      '${DateFormat.yMMMd(fr ? "fr" : "en").format(_customRange!.end)}',
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(fr ? 'Contenu' : 'Content', style: sectionStyle),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeDescription,
          onChanged: (v) => setState(() {
            _includeDescription = v;
            _previewVersion++;
          }),
          title: Text(
            fr ? 'Inclure les descriptions' : 'Include descriptions',
            style: const TextStyle(fontSize: 13.5),
          ),
          subtitle: Text(
            fr
                ? 'Ajoute les notes sous chaque événement'
                : 'Show notes under each event',
            style: const TextStyle(fontSize: 11.5),
          ),
          secondary: const Icon(Icons.notes_rounded, size: 20),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _groupByMonth,
          onChanged: (v) => setState(() {
            _groupByMonth = v;
            _previewVersion++;
          }),
          title: Text(fr ? 'Grouper par mois' : 'Group by month',
              style: const TextStyle(fontSize: 13.5)),
          subtitle: Text(
              fr
                  ? 'Organise les événements par mois'
                  : 'Organise events by month',
              style: const TextStyle(fontSize: 11.5)),
          secondary: const Icon(Icons.view_agenda_outlined, size: 20),
        ),
        const SizedBox(height: 20),
        _summaryCard(
          fr: fr,
          leftLabel: fr ? 'Événements' : 'Events',
          leftValue: '${filtered.length}',
          rightLabel: fr ? 'Mois' : 'Months',
          rightValue: '${_monthsCount(filtered)}',
          footer: rangeLabel,
        ),
      ],
    );
  }

  Widget _buildCalendarOptions(
      BuildContext context, bool fr, _ProviderSnapshot snapshot) {
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3);

    final now = DateTime.now().year;
    final years = List<int>.generate(21, (i) => now - 10 + i);

    final calName = snapshot.selectedCalendar?.name ?? '';
    final secondaryName = snapshot.secondaryCalendarId != null &&
            snapshot.secondaryCalendarId != snapshot.selectedCalendarId
        ? (snapshot.calendars.firstWhere(
            (c) => c.id == snapshot.secondaryCalendarId,
            orElse: () => snapshot.selectedCalendar!,
          ).name)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(fr ? 'Année à exporter' : 'Year to export', style: sectionStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _calendarYear,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
          onChanged: (y) {
            if (y != null) {
              setState(() {
                _calendarYear = y;
                _previewVersion++;
              });
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          fr
              ? 'Les grilles affichent les 12 mois grégoriens de cette année.'
              : 'Grids render all 12 Gregorian months of that year.',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Text(fr ? 'Mise en page' : 'Layout', style: sectionStyle),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(fr ? '2 / page' : '2 per page',
                  style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.auto_stories_rounded, size: 18),
            ),
            ButtonSegment(
              value: false,
              label: Text(fr ? '1 / page' : '1 per page',
                  style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.crop_portrait_rounded, size: 18),
            ),
          ],
          selected: {_twoMonthsPerPage},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() {
            _twoMonthsPerPage = s.first;
            _previewVersion++;
          }),
        ),
        const SizedBox(height: 20),
        Text(fr ? 'Détails' : 'Details', style: sectionStyle),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _showEventDots,
          onChanged: (v) => setState(() {
            _showEventDots = v;
            _previewVersion++;
          }),
          title: Text(fr ? 'Marqueurs d\'événements' : 'Event markers',
              style: const TextStyle(fontSize: 13.5)),
          subtitle: Text(
              fr
                  ? 'Une barre colorée sur les jours avec événements'
                  : 'A coloured bar on days with events',
              style: const TextStyle(fontSize: 11.5)),
          secondary: const Icon(Icons.radio_button_checked, size: 20),
        ),
        const SizedBox(height: 16),
        _summaryCard(
          fr: fr,
          leftLabel: fr ? 'Calendrier' : 'Calendar',
          leftValue: calName.isEmpty ? '—' : calName,
          rightLabel: fr ? 'Secondaire' : 'Secondary',
          rightValue: secondaryName ?? (fr ? 'Aucun' : 'None'),
          footer:
              fr ? '12 mois · $_calendarYear' : '12 months · $_calendarYear',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fr
                      ? 'Chaque cellule affiche la date grégorienne et, si configurée, la date du calendrier secondaire.'
                      : 'Each cell shows the Gregorian date and, if configured, the secondary calendar\'s date.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required bool fr,
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    required String footer,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 18),
              const SizedBox(width: 8),
              Text(fr ? 'Aperçu' : 'Summary',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile(leftValue, leftLabel)),
              const SizedBox(width: 10),
              Expanded(child: _statTile(rightValue, rightLabel)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(footer,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, _RangePreset preset) {
    final selected = _preset == preset;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      avatar: selected ? const Icon(Icons.check_rounded, size: 16) : null,
      onSelected: (_) => setState(() {
        _preset = preset;
        _previewVersion++;
      }),
    );
  }

  Widget _statTile(String value, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // PDF — EVENTS MODE
  // ───────────────────────────────────────────────────────────────────────
  Future<Uint8List> _buildEventsPdf(
    PdfPageFormat format,
    List<_Ev> events,
    String localeCode,
    String rangeLabel,
  ) async {
    final doc = pw.Document(
      title: 'Universal Calendar Export',
      author: 'Universal Calendar',
      creator: 'Universal Calendar',
      subject: 'Calendar Events',
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );

    final generated =
        DateFormat.yMMMMd(localeCode).add_Hm().format(DateTime.now());

    final groups = <String, List<_Ev>>{};
    for (final e in events) {
      final key = e.date != null
          ? DateFormat.yMMMM(localeCode).format(e.date!)
          : (localeCode == 'fr' ? 'Sans date' : 'Undated');
      groups.putIfAbsent(key, () => []).add(e);
    }

    doc.addPage(_eventsCoverPage(
        format, events, groups, rangeLabel, localeCode, generated));
    doc.addPage(_eventsContentPage(
        format, events, groups, localeCode, generated, rangeLabel));

    return doc.save();
  }

  pw.Page _eventsCoverPage(
    PdfPageFormat format,
    List<_Ev> events,
    Map<String, List<_Ev>> groups,
    String rangeLabel,
    String localeCode,
    String generated,
  ) {
    final fr = localeCode == 'fr';
    return pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => _gradientCover(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _coverHeader(fr, 'Universal Calendar', 'UC'),
            pw.Spacer(),
            _coverBadge(fr ? 'EXPORT DU CALENDRIER' : 'CALENDAR EXPORT'),
            pw.SizedBox(height: 18),
            pw.Text(
              fr
                  ? 'Vos événements,\nélégamment organisés'
                  : 'Your events,\nbeautifully organised',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 40,
                color: PdfColors.white,
                lineSpacing: 4,
                height: 1.15,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(rangeLabel,
                style: pw.TextStyle(
                    fontSize: 13, color: PdfColor.fromInt(0xFFE9D5FF))),
            pw.Spacer(),
            pw.Container(
                height: 0.6, color: PdfColor.fromInt(0x33FFFFFF)),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                _coverStat(fr ? 'Événements' : 'Events', '${events.length}'),
                pw.SizedBox(width: 36),
                _coverStat(fr ? 'Mois' : 'Months', '${groups.length}'),
                pw.SizedBox(width: 36),
                _coverStat(fr ? 'Généré' : 'Generated', generated),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.MultiPage _eventsContentPage(
    PdfPageFormat format,
    List<_Ev> events,
    Map<String, List<_Ev>> groups,
    String localeCode,
    String generated,
    String rangeLabel,
  ) {
    final fr = localeCode == 'fr';
    return pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 44),
      header: (ctx) => _contentHeader(fr, rangeLabel),
      footer: (ctx) => _contentFooter(fr, generated, ctx),
      build: (ctx) {
        final widgets = <pw.Widget>[];
        widgets.add(_introCard(fr, events.length, groups.length));
        widgets.add(pw.SizedBox(height: 18));

        if (events.isEmpty) {
          widgets.add(_emptyState(fr));
        } else if (_groupByMonth) {
          for (final entry in groups.entries) {
            widgets.add(_monthHeader(entry.key, entry.value.length));
            for (final e in entry.value) {
              widgets.add(_eventCard(e, localeCode));
            }
            widgets.add(pw.SizedBox(height: 14));
          }
        } else {
          for (final e in events) {
            widgets.add(_eventCard(e, localeCode));
          }
        }
        return widgets;
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // PDF — CALENDAR MODE
  // ───────────────────────────────────────────────────────────────────────
  Future<Uint8List> _buildCalendarPdf(
    PdfPageFormat format,
    _ProviderSnapshot snapshot,
    String localeCode,
  ) async {
    final doc = pw.Document(
      title: 'Universal Calendar $_calendarYear',
      author: 'Universal Calendar',
      creator: 'Universal Calendar',
      subject: 'Calendar Grid',
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );

    final generated =
        DateFormat.yMMMMd(localeCode).add_Hm().format(DateTime.now());

    final eventDates = <String>{};
    for (final e in snapshot.events) {
      if (e.calendarId == snapshot.selectedCalendarId) {
        eventDates.add(e.date);
      }
    }

    doc.addPage(_calendarCoverPage(
        format, snapshot, localeCode, generated, eventDates.length));

    if (_twoMonthsPerPage) {
      for (int m = 1; m <= 12; m += 2) {
        doc.addPage(_twoMonthPage(
            format, snapshot, localeCode, m, m + 1, eventDates));
      }
    } else {
      for (int m = 1; m <= 12; m++) {
        doc.addPage(_oneMonthPage(
            format, snapshot, localeCode, m, eventDates));
      }
    }

    return doc.save();
  }

  pw.Page _calendarCoverPage(
    PdfPageFormat format,
    _ProviderSnapshot snapshot,
    String localeCode,
    String generated,
    int eventCount,
  ) {
    final fr = localeCode == 'fr';
    final calName = snapshot.selectedCalendar?.name ?? 'Universal Calendar';
    return pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => _gradientCover(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _coverHeader(fr, calName, 'UC'),
            pw.Spacer(),
            _coverBadge(fr ? 'CALENDRIER ANNUEL' : 'YEAR CALENDAR'),
            pw.SizedBox(height: 18),
            pw.Text(
              '$_calendarYear',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 76,
                color: PdfColors.white,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              fr
                  ? '12 mois de dates grégoriennes\navec les dates secondaires superposées'
                  : '12 months of Gregorian dates\nwith secondary calendar dates overlaid',
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColor.fromInt(0xFFE9D5FF),
                lineSpacing: 4,
              ),
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0x1AFFFFFF),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(
                    color: PdfColor.fromInt(0x33FFFFFF), width: 0.6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    fr ? 'LÉGENDE' : 'LEGEND',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFFFBBF24),
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      // Event indicator bar
                      pw.Container(
                        width: 12,
                        height: 2.5,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFFBBF24),
                          borderRadius: pw.BorderRadius.circular(1),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        fr ? 'Jour avec événement' : 'Day with event',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromInt(0xFFE9D5FF)),
                      ),
                      pw.SizedBox(width: 18),
                      // Special day dot
                      pw.Container(
                        width: 5,
                        height: 5,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColor.fromInt(0xFFF59E0B),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        fr ? 'Jour spécial' : 'Special day',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromInt(0xFFE9D5FF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
                height: 0.6, color: PdfColor.fromInt(0x33FFFFFF)),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                _coverStat(fr ? 'Année' : 'Year', '$_calendarYear'),
                pw.SizedBox(width: 36),
                _coverStat(fr ? 'Événements' : 'Events', '$eventCount'),
                pw.SizedBox(width: 36),
                _coverStat(fr ? 'Généré' : 'Generated', generated),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _oneMonthPage(
    PdfPageFormat format,
    _ProviderSnapshot snapshot,
    String localeCode,
    int month,
    Set<String> eventDates,
  ) {
    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(50, 46, 50, 40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _pageHeader(localeCode, snapshot),
          pw.SizedBox(height: 24),
          pw.Expanded(
            child: _monthGrid(
              month: month,
              localeCode: localeCode,
              snapshot: snapshot,
              eventDates: eventDates,
              cellHeight: 68,
              isLarge: true,
            ),
          ),
          _pageFooter(localeCode, ctx),
        ],
      ),
    );
  }

  pw.Page _twoMonthPage(
    PdfPageFormat format,
    _ProviderSnapshot snapshot,
    String localeCode,
    int m1,
    int m2,
    Set<String> eventDates,
  ) {
    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(46, 42, 46, 38),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _pageHeader(localeCode, snapshot),
          pw.SizedBox(height: 14),
          pw.Expanded(
            child: _monthGrid(
              month: m1,
              localeCode: localeCode,
              snapshot: snapshot,
              eventDates: eventDates,
              cellHeight: 44,
              isLarge: false,
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Expanded(
            child: _monthGrid(
              month: m2,
              localeCode: localeCode,
              snapshot: snapshot,
              eventDates: eventDates,
              cellHeight: 44,
              isLarge: false,
            ),
          ),
          _pageFooter(localeCode, ctx),
        ],
      ),
    );
  }

  // ── BEAUTY-UPGRADED MONTH GRID ─────────────────────────────────────────
  pw.Widget _monthGrid({
    required int month,
    required String localeCode,
    required _ProviderSnapshot snapshot,
    required Set<String> eventDates,
    required double cellHeight,
    bool isLarge = false,
  }) {
    final firstDay = DateTime(_calendarYear, month, 1);
    final lastDay = DateTime(_calendarYear, month + 1, 0);
    final daysInMonth = lastDay.day;

    final firstWeekday = firstDay.weekday; // 1 = Mon … 7 = Sun
    final startOffset = firstWeekday - 1;

    final primaryMonthName = DateFormat.MMMM(localeCode).format(firstDay);
    final comparisonCal = _comparisonCalendar(snapshot);
    final calMonthRange = comparisonCal != null
        ? _monthRangeLabel(comparisonCal, firstDay, lastDay)
        : null;

    final weekdayLabels = List<String>.generate(7, (i) {
      final d = DateTime(2024, 1, 1 + i); // 2024-01-01 is Monday
      return DateFormat('EEEE', localeCode).format(d);
    });

    // Detect special days accurately: for each Gregorian day, look up the
    // primary calendar's (month, day) and match against the specialDays list.
    final specialDaysByGregorianDay = <int>{};
    final primaryCal = snapshot.selectedCalendar;
    if (primaryCal != null && primaryCal.specialDays.isNotEmpty) {
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(_calendarYear, month, d);
        try {
          final info = CalendarMath.getCalendarDateInfo(primaryCal, date);
          final calMonth = info['month'] as int?;
          final calDay = info['day'] as int?;
          if (calMonth != null && calDay != null) {
            if (primaryCal.specialDays
                .any((sd) => sd.month == calMonth && sd.day == calDay)) {
              specialDaysByGregorianDay.add(d);
            }
          }
        } catch (_) {}
      }
    }

    // Build the cell grid (leading blanks + days + trailing blanks)
    final cells = <pw.Widget>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(pw.SizedBox(height: cellHeight));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_calendarYear, month, d);
      final dateStr = CalendarMath.formatDate(date, 'YYYY-MM-DD');
      final hasEvents = _showEventDots && eventDates.contains(dateStr);
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
      final isToday = _isToday(date);
      final isSpecial = specialDaysByGregorianDay.contains(d);

      String? secondaryText;
      if (comparisonCal != null &&
          comparisonCal.calendarType != 'gregorian') {
        try {
          final info =
              CalendarMath.getCalendarDateInfo(comparisonCal, date);
          secondaryText = '${info['day']}';
        } catch (_) {}
      }

      cells.add(_dayCell(
        day: d,
        secondaryText: secondaryText,
        hasEvents: hasEvents,
        isWeekend: isWeekend,
        isToday: isToday,
        isSpecial: isSpecial,
        cellHeight: cellHeight,
        isLarge: isLarge,
      ));
    }
    final totalCells = cells.length;
    final rows = (totalCells / 7).ceil();
    final filledCells = rows * 7;
    for (int i = totalCells; i < filledCells; i++) {
      cells.add(pw.SizedBox(height: cellHeight));
    }

    // Build table rows with alternating backgrounds
    final gridRows = <pw.TableRow>[];
    for (int r = 0; r < rows; r++) {
      final rowCells = cells.sublist(r * 7, (r + 1) * 7);
      gridRows.add(pw.TableRow(
        decoration: r.isEven
            ? pw.BoxDecoration(color: PdfColor.fromInt(0xFFFDFCFF))
            : null,
        children: rowCells
            .map((c) => pw.Container(height: cellHeight, child: c))
            .toList(),
      ));
    }

    // Month header: purple accent bar + name + secondary range + year pill
    final monthHeader = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 5,
          height: isLarge ? 42 : 32,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF7C3AED),
            borderRadius: pw.BorderRadius.circular(2.5),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                primaryMonthName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: isLarge ? 26 : 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F2937),
                  letterSpacing: isLarge ? 3 : 2.5,
                ),
              ),
              if (calMonthRange != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  calMonthRange,
                  style: pw.TextStyle(
                    fontSize: isLarge ? 10 : 8.5,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColor.fromInt(0xFF7C3AED),
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F3FF),
            borderRadius: pw.BorderRadius.circular(20),
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFDDD6FE),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            '$_calendarYear',
            style: pw.TextStyle(
              fontSize: isLarge ? 11 : 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF5B21B6),
            ),
          ),
        ),
      ],
    );

    // Weekday header row — Sat/Sun coloured purple
    final weekdayRow = pw.Row(
      children: weekdayLabels.asMap().entries.map((e) {
        final i = e.key;
        final label = e.value;
        final isWeekendCol = i >= 5;
        return pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: isLarge ? 6 : 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: isLarge ? 8 : 6.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
                color: isWeekendCol
                    ? PdfColor.fromInt(0xFF9F7AEA)
                    : PdfColor.fromInt(0xFF6B7280),
              ),
            ),
          ),
        );
      }).toList(),
    );

    // Assemble: header → rounded outer container → weekday row + table
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        monthHeader,
        pw.SizedBox(height: isLarge ? 14 : 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFE5E7EB),
              width: 0.6,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              weekdayRow,
              pw.Container(
                height: 0.6,
                color: PdfColor.fromInt(0xFFE5E7EB),
              ),
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFF0F0F5),
                    width: 0.3,
                  ),
                ),
                children: gridRows,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── BEAUTY-UPGRADED DAY CELL ───────────────────────────────────────────
  pw.Widget _dayCell({
    required int day,
    String? secondaryText,
    required bool hasEvents,
    required bool isWeekend,
    required bool isToday,
    required bool isSpecial,
    required double cellHeight,
    required bool isLarge,
  }) {
    PdfColor bg;
    PdfColor numberColor;
    PdfColor secondaryColor;

    if (isToday) {
      bg = PdfColor.fromInt(0xFF7C3AED);
      numberColor = PdfColors.white;
      secondaryColor = PdfColor.fromInt(0xFFE9D5FF);
    } else if (isWeekend) {
      bg = PdfColor.fromInt(0xFFFBF7FF);
      numberColor = PdfColor.fromInt(0xFF111827);
      secondaryColor = PdfColor.fromInt(0xFF9CA3AF);
    } else {
      bg = PdfColors.white;
      numberColor = PdfColor.fromInt(0xFF111827);
      secondaryColor = PdfColor.fromInt(0xFF9CA3AF);
    }

    final double numberSize = isLarge
      ? (cellHeight >= 80 ? 15 : 12)
      : (cellHeight >= 55 ? 10.5 : 8.5);
    final double secondarySize = isLarge
      ? (cellHeight >= 80 ? 9 : 7)
      : (cellHeight >= 55 ? 7 : 5.5);

    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(
        isLarge ? 7 : 5,
        isLarge ? 5 : 3.5,
        isLarge ? 5 : 3.5,
        isLarge ? 4 : 2.5,
      ),
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$day',
                style: pw.TextStyle(
                  fontSize: numberSize,
                  fontWeight: isToday
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: numberColor,
                  lineSpacing: 0,
                ),
              ),
              if (secondaryText != null && cellHeight >= 32)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(
                    secondaryText,
                    style: pw.TextStyle(
                      fontSize: secondarySize,
                      color: secondaryColor,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          if (isSpecial)
            pw.Positioned(
              top: 0,
              right: 0,
              child: pw.Container(
                width: isLarge ? 5 : 4,
                height: isLarge ? 5 : 4,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: isToday
                      ? PdfColor.fromInt(0xFFFBBF24)
                      : PdfColor.fromInt(0xFFF59E0B),
                ),
              ),
            ),
          if (hasEvents)
            pw.Positioned(
              bottom: 0,
              left: isLarge ? 5 : 3.5,
              right: isLarge ? 5 : 3.5,
              child: pw.Container(
                height: isLarge ? 2.5 : 2,
                decoration: pw.BoxDecoration(
                  color: isToday
                      ? PdfColor.fromInt(0xFFFBBF24)
                      : PdfColor.fromInt(0xFF7C3AED),
                  borderRadius: pw.BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  CalendarModel? _comparisonCalendar(_ProviderSnapshot snapshot) {
    if (snapshot.secondaryCalendarId != null &&
        snapshot.secondaryCalendarId != snapshot.selectedCalendarId) {
      try {
        return snapshot.calendars
            .firstWhere((c) => c.id == snapshot.secondaryCalendarId);
      } catch (_) {}
    }
    final sel = snapshot.selectedCalendar;
    if (sel != null && sel.calendarType != 'gregorian') {
      return sel;
    }
    return null;
  }

  String? _monthRangeLabel(
      CalendarModel cal, DateTime firstDay, DateTime lastDay) {
    try {
      final info1 = CalendarMath.getCalendarDateInfo(cal, firstDay);
      final info2 = CalendarMath.getCalendarDateInfo(cal, lastDay);
      final m1 = info1['monthName'] as String? ?? '';
      final m2 = info2['monthName'] as String? ?? '';
      final y1 = info1['year'];
      final y2 = info2['year'];
      if (m1 == m2 && y1 == y2) return '$m1 $y1';
      if (y1 == y2) return '$m1 – $m2 $y1';
      return '$m1 $y1 – $m2 $y2';
    } catch (_) {
      return null;
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  // ── BEAUTY-UPGRADED PAGE HEADER ────────────────────────────────────────
  pw.Widget _pageHeader(String localeCode, _ProviderSnapshot snapshot) {
    final fr = localeCode == 'fr';
    final calName = snapshot.selectedCalendar?.name ?? '';
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColor.fromInt(0xFF7C3AED),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                (fr ? 'Calendrier universel' : 'Universal Calendar')
                    .toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF7C3AED),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (calName.isNotEmpty)
            pw.Text(
              calName,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF6B7280),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(String localeCode, pw.Context ctx) {
    final fr = localeCode == 'fr';
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
              color: PdfColor.fromInt(0xFFE5E7EB), width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$_calendarYear',
            style: pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9CA3AF)),
          ),
          pw.Text(
            '${fr ? "Page" : "Page"} ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  // ── SHARED COVER PIECES ───────────────────────────────────────────────
  pw.Widget _gradientCover({required pw.Widget child}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColor.fromInt(0xFF3B0764),
            PdfColor.fromInt(0xFF6D28D9),
            PdfColor.fromInt(0xFF8B5CF6),
          ],
          stops: const [0, 0.6, 1],
        ),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            top: -120,
            right: -100,
            child: pw.Container(
              width: 320,
              height: 320,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(0x1AFFFFFF),
              ),
            ),
          ),
          pw.Positioned(
            bottom: -140,
            left: -120,
            child: pw.Container(
              width: 360,
              height: 360,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(0x14FFFFFF),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(48),
            child: child,
          ),
        ],
      ),
    );
  }

  pw.Widget _coverHeader(bool fr, String name, String initials) {
    return pw.Row(
      children: [
        pw.Container(
          width: 46,
          height: 46,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFBBF24),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            initials,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 15,
              color: PdfColor.fromInt(0xFF3B0764),
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _coverBadge(String text) => pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0x33FBBF24),
          borderRadius: pw.BorderRadius.circular(20),
          border:
              pw.Border.all(color: PdfColor.fromInt(0xFFFBBF24), width: 0.8),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColor.fromInt(0xFFFDE68A),
            letterSpacing: 2,
          ),
        ),
      );

  pw.Widget _coverStat(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
            color: PdfColor.fromInt(0xFFC4B5FD),
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 14,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  pw.Widget _contentHeader(bool fr, String rangeLabel) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
              color: PdfColor.fromInt(0xFFE5E7EB), width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            fr ? 'Calendrier universel' : 'Universal Calendar',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColor.fromInt(0xFF6B7280),
            ),
          ),
          pw.Text(
            rangeLabel,
            style: pw.TextStyle(
                fontSize: 9, color: PdfColor.fromInt(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  pw.Widget _contentFooter(bool fr, String generated, pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
              color: PdfColor.fromInt(0xFFE5E7EB), width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${fr ? "Généré le" : "Generated"} $generated',
            style: pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9CA3AF)),
          ),
          pw.Text(
            '${fr ? "Page" : "Page"} ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  pw.Widget _introCard(bool fr, int count, int months) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F3FF),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(
            color: PdfColor.fromInt(0xFFDDD6FE), width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 44,
            height: 44,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF7C3AED),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              '$count',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  fr ? 'Résumé de l\'export' : 'Export summary',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: PdfColor.fromInt(0xFF4C1D95),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  fr
                      ? '$count événement(s) répartis sur $months mois. Préparé avec soin pour vous.'
                      : '$count event(s) across $months month(s). Crafted with care for you.',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColor.fromInt(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _monthHeader(String label, int count) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 22,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF59E0B),
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 15,
                color: PdfColor.fromInt(0xFF1F2937),
                letterSpacing: 0.2,
              ),
            ),
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFEF3C7),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              '$count',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColor.fromInt(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _eventCard(_Ev e, String localeCode) {
    final fr = localeCode == 'fr';
    final day =
        e.date != null ? DateFormat.d(localeCode).format(e.date!) : '—';
    final weekday = e.date != null
        ? DateFormat.E(localeCode).format(e.date!)
        : (fr ? 'N/D' : 'n/a');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
            color: PdfColor.fromInt(0xFFE5E7EB), width: 0.7),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 52,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F3FF),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFDDD6FE), width: 0.7),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  day,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 17,
                    color: PdfColor.fromInt(0xFF5B21B6),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  weekday.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 7,
                    color: PdfColor.fromInt(0xFF8B5CF6),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  e.title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11.5,
                    color: PdfColor.fromInt(0xFF111827),
                  ),
                ),
                if (e.time != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 4,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColor.fromInt(0xFFF59E0B),
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        e.time!,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_includeDescription &&
                    e.description != null &&
                    e.description!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    e.description!,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF4B5563),
                      lineSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyState(bool fr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
            color: PdfColor.fromInt(0xFFE5E7EB), width: 0.8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            fr ? 'Aucun événement' : 'No events',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColor.fromInt(0xFF374151),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            fr
                ? 'Ajoutez des événements ou modifiez la plage de dates pour voir le contenu ici.'
                : 'Add events or change the date range to see content here.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF6B7280),
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SNAPSHOT — captures provider state so the PDF builder doesn't hold a live
// provider reference (avoids rebuild loops inside PdfPreview).
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderSnapshot {
  final List<dynamic> events;
  final CalendarModel? selectedCalendar;
  final String? secondaryCalendarId;
  final List<CalendarModel> calendars;
  final String? selectedCalendarId;

  const _ProviderSnapshot({
    required this.events,
    required this.selectedCalendar,
    required this.secondaryCalendarId,
    required this.calendars,
    required this.selectedCalendarId,
  });
}