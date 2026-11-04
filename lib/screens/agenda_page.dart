import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/formatters.dart';
import '../l10n/tr.dart';
import 'add_event_page.dart';
import 'event_detail_page.dart';

enum _RangeFilter { all, today, week, month, upcoming }

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  _RangeFilter _range = _RangeFilter.all;
  String? _calendarFilter; // null = all calendars

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────
  List<CalendarEvent> _getFiltered(CalendarProvider provider) {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return provider.events.where((event) {
      // Calendar filter
      if (_calendarFilter != null && event.calendarId != _calendarFilter) {
        return false;
      }

      // Date range filter
      DateTime? parsed;
      try {
        final parts = event.date.split('-').map(int.parse).toList();
        if (parts.length == 3) {
          parsed = DateTime(parts[0], parts[1], parts[2]);
        }
      } catch (_) {}

      if (_range != _RangeFilter.all && parsed != null) {
        switch (_range) {
          case _RangeFilter.today:
            if (parsed != today) return false;
            break;
          case _RangeFilter.week:
            final weekEnd = today.add(const Duration(days: 7));
            if (parsed.isBefore(today) || parsed.isAfter(weekEnd)) {
              return false;
            }
            break;
          case _RangeFilter.month:
            if (parsed.year != today.year || parsed.month != today.month) {
              return false;
            }
            break;
          case _RangeFilter.upcoming:
            if (parsed.isBefore(today)) return false;
            break;
          case _RangeFilter.all:
            break;
        }
      }

      // Search query
      if (q.isEmpty) return true;
      final title = event.title.toLowerCase();
      final notes = event.notes.toLowerCase();
      final dateStr = event.date.toLowerCase();
      return title.contains(q) ||
          notes.contains(q) ||
          dateStr.contains(q);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
    final grouped = <String, List<CalendarEvent>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.date, () => []).add(e);
    }
    // Sort each group by time
    for (final list in grouped.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    return grouped;
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = context.watch<CalendarProvider>();
    final localeCode = context.watch<LocaleProvider>().languageCode;

    final filtered = _getFiltered(provider);
    final grouped = _groupByDate(filtered);
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr(context, 'Agenda')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (filtered.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          if (provider.calendars.length > 1)
            _buildCalendarFilter(context, provider),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, provider)
                : _buildEventList(
                    context, provider, grouped, sortedDates, localeCode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEventPage()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(tr(context, 'Add event')),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: tr(context, 'Search events by title, notes, or date'),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final chips = <(String, _RangeFilter)>[
      (tr(context, 'All'), _RangeFilter.all),
      (tr(context, 'Today'), _RangeFilter.today),
      (tr(context, 'This week'), _RangeFilter.week),
      (tr(context, 'This month'), _RangeFilter.month),
      (tr(context, 'Upcoming'), _RangeFilter.upcoming),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = chips[i];
          final selected = _range == value;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _range = value),
          );
        },
      ),
    );
  }

  Widget _buildCalendarFilter(
      BuildContext context, CalendarProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: provider.calendars.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              final selected = _calendarFilter == null;
              return FilterChip(
                avatar: const Icon(Icons.apps_rounded, size: 16),
                label: Text(
                  tr(context, 'All calendars'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _calendarFilter = null),
              );
            }
            final cal = provider.calendars[i - 1];
            final selected = _calendarFilter == cal.id;
            return FilterChip(
              avatar: Text(cal.emoji,
                  style: const TextStyle(fontSize: 14)),
              label: Text(
                cal.name,
                style: TextStyle(
                  fontSize: 11.5,
                  color: selected ? cal.color : null,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: selected,
              selectedColor: cal.color.withValues(alpha: 0.18),
              onSelected: (_) => setState(() =>
                  _calendarFilter = selected ? null : cal.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    CalendarProvider provider,
    Map<String, List<CalendarEvent>> grouped,
    List<String> sortedDates,
    String localeCode,
  ) {
    final items = <Widget>[];
    for (final dateStr in sortedDates) {
      final events = grouped[dateStr]!;
      items.add(_dateHeader(
          context, dateStr, events.length, localeCode));
      for (final event in events) {
        items.add(_eventCard(
            context, provider, event, localeCode));
      }
    }
    items.add(const SizedBox(height: 96));

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: items,
    );
  }

  Widget _dateHeader(BuildContext context, String dateStr, int count,
      String localeCode) {
    DateTime? date;
    try {
      final parts = dateStr.split('-').map(int.parse).toList();
      if (parts.length == 3) {
        date = DateTime(parts[0], parts[1], parts[2]);
      }
    } catch (_) {}

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String label;
    String? subtitle;
    if (date != null) {
      if (date == today) {
        label = tr(context, 'Today');
        subtitle = DateFormat('EEEE, d MMMM y', localeCode).format(date);
      } else if (date == tomorrow) {
        label = tr(context, 'Tomorrow');
        subtitle = DateFormat('EEEE, d MMMM y', localeCode).format(date);
      } else {
        label = DateFormat('EEEE', localeCode).format(date).toUpperCase();
        subtitle = DateFormat('d MMMM y', localeCode).format(date);
      }
    } else {
      label = dateStr;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .primaryColor
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    CalendarProvider provider,
    CalendarEvent event,
    String localeCode,
  ) {
    final cal = provider.calendars.firstWhere(
      (c) => c.id == event.calendarId,
      orElse: () => provider.calendars.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                  left: BorderSide(color: event.color, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            event.isAllDay
                                ? Icons.wb_sunny_outlined
                                : Icons.schedule_rounded,
                            size: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.isAllDay
                                ? tr(context, 'All day')
                                : '${event.time} – ${formatEventEnd(event)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(cal.emoji.isNotEmpty
                              ? Icons.circle
                              : Icons.circle,
                              size: 6,
                              color: cal.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              cal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (event.reminderMinutesBefore != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color:
                          Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, CalendarProvider provider) {
    final noEvents = provider.events.isEmpty;
    final hasQuery = _query.trim().isNotEmpty;

    final title = noEvents
        ? tr(context, 'No events yet')
        : hasQuery
            ? tr(context, 'No matches')
            : tr(context, 'Nothing in this period');

    final subtitle = noEvents
        ? tr(context,
            'Tap + to add your first event and it will appear here.')
        : hasQuery
            ? tr(context,
                'Try a different search or clear your filters.')
            : tr(context, 'Try another date range or tap All.');

    final icon = noEvents
        ? Icons.event_note_rounded
        : hasQuery
            ? Icons.search_off_rounded
            : Icons.inbox_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .primaryColor
                    .withValues(alpha: 0.10),
              ),
              child: Icon(
                icon,
                size: 34,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color:
                    Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (hasQuery || _range != _RangeFilter.all) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _range = _RangeFilter.all;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr(context, 'Clear filters')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}