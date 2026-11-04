import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../models/calendar_model.dart';
import '../models/special_day.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';
import 'add_event_page.dart';
import 'equivalents_page.dart';
import 'event_detail_page.dart';

class DayViewPage extends StatefulWidget {
  final DateTime selectedDate;
  const DayViewPage({super.key, required this.selectedDate});

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  late DateTime _currentDate;
  late final ScrollController _stripController;

  static const int _stripWindow = 200;
  static const double _stripTileWidth = 62;
  static const double _stripPadding = 4;

  // Timeline layout constants
  static const double _labelWidth = 68;
  static const double _spineWidth = 28;
  static const double _dotColumnTop = 14;

  final Map<String, DateFormat> _fmtCache = {};
  final Map<String, List<CalendarEvent>> _eventsByDate = {};
  String? _eventsFingerprint;

  @override
  void initState() {
    super.initState();
    _currentDate = _dateOnly(widget.selectedDate);
    _stripController = ScrollController(
      initialScrollOffset: _stripCentreOffset(widget.selectedDate),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollStripToCentre(_currentDate, animate: false);
      Provider.of<CalendarProvider>(context, listen: false)
          .selectDate(_currentDate);
    });
  }

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateKey(DateTime d) => CalendarMath.formatDate(d, 'YYYY-MM-DD');

  DateFormat _fmt(String pattern, String locale) {
    final key = '$pattern|$locale';
    return _fmtCache.putIfAbsent(key, () => DateFormat(pattern, locale));
  }

  // ── Strip scroll math ────────────────────────────────────────────────
  static double _stripCentreOffset(DateTime date) {
    final today = _dateOnly(DateTime.now());
    return (_stripWindow + today.difference(date).inDays) * _stripTileWidth;
  }

  double _targetScrollFor(DateTime date, ScrollPosition pos) {
    final raw = _stripCentreOffset(date) -
        pos.viewportDimension / 2 +
        _stripTileWidth / 2;
    final max = pos.hasContentDimensions ? pos.maxScrollExtent : double.infinity;
    return raw.clamp(0.0, max);
  }

  void _scrollStripToCentre(DateTime date, {bool animate = true}) {
    if (!_stripController.hasClients) return;
    final pos = _stripController.position;
    if (!pos.hasContentDimensions) return;
    final target = _targetScrollFor(date, pos);
    if (animate) {
      _stripController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _stripController.jumpTo(target);
    }
  }

  void _settleStrip() {
    if (!_stripController.hasClients) return;
    final pos = _stripController.position;
    if (!pos.hasContentDimensions || pos.viewportDimension == 0) return;
    final target = _targetScrollFor(_currentDate, pos);
    if ((pos.pixels - target).abs() <= _stripTileWidth / 2) return;
    _scrollStripToCentre(_currentDate);
  }

  void _jumpTo(DateTime date, {bool syncProvider = true}) {
    final next = _dateOnly(date);
    if (next == _currentDate) return;
    setState(() => _currentDate = next);
    if (syncProvider) {
      Provider.of<CalendarProvider>(context, listen: false).selectDate(next);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollStripToCentre(next);
    });
  }

  void _shiftDay(int delta) => _jumpTo(_currentDate.add(Duration(days: delta)));

  // ── Event cache ───────────────────────────────────────────────────────
  String _fingerprint(CalendarProvider p) {
    final evts = p.events;
    if (evts.isEmpty) return 'empty|${p.selectedCalendarId}';
    return '${evts.length}|${evts.first.id}|${evts.last.id}|${p.selectedCalendarId}';
  }

  List<CalendarEvent> _dayEvents(CalendarProvider provider, DateTime date) {
    final fp = _fingerprint(provider);
    if (_eventsFingerprint != fp) {
      _eventsFingerprint = fp;
      _eventsByDate.clear();
      for (final event in provider.events) {
        if (event.calendarId != provider.selectedCalendarId) continue;
        _eventsByDate.putIfAbsent(event.date, () => []).add(event);
      }
      for (final list in _eventsByDate.values) {
        list.sort((a, b) => a.time.compareTo(b.time));
      }
    }
    return _eventsByDate[_dateKey(date)] ?? const <CalendarEvent>[];
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().languageCode;
    final provider = Provider.of<CalendarProvider>(context);
    final cal = provider.selectedCalendar;
    final secondaryCal = provider.secondaryCalendarId != null && cal != null
        ? provider.calendars.firstWhere(
            (c) => c.id == provider.secondaryCalendarId,
            orElse: () => cal,
          )
        : null;

    final info = cal == null
        ? const <String, dynamic>{}
        : CalendarMath.getCalendarDateInfo(cal, _currentDate);
    final dayNumber = (info['day'] as int?) ?? _currentDate.day;
    final monthName = (info['monthName'] as String?) ??
        _fmt('MMMM', locale).format(_currentDate);
    final yearNumber = (info['year'] as int?) ?? _currentDate.year;

    final dayEvents = _dayEvents(provider, _currentDate);
    final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
    final timedEvents = dayEvents.where((e) => !e.isAllDay).toList();
    final specials = cal == null
        ? const <SpecialDay>[]
        : cal.specialDays
            .where((sd) =>
                sd.month == (info['month'] as int? ?? -1) &&
                sd.day == dayNumber)
            .toList();

    final accent =
        cal == null ? Theme.of(context).primaryColor : _hexColor(cal.colorHex);
    final isToday = _dateOnly(DateTime.now()) == _currentDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -220) _shiftDay(1);
          if (v > 220) _shiftDay(-1);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _hero(
                context: context,
                accent: accent,
                isDark: isDark,
                isToday: isToday,
                dayNumber: dayNumber,
                monthName: monthName,
                yearNumber: yearNumber,
                locale: locale,
                secondaryCal: secondaryCal,
                eventCount: dayEvents.length,
                specials: specials,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StripHeader(
                height: 76,
                background: Theme.of(context).scaffoldBackgroundColor,
                child: _dayStrip(context, locale, accent),
              ),
            ),
            if (allDayEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: _allDaySection(context, allDayEvents, accent),
              ),
            SliverToBoxAdapter(
              child: _sectionLabel(context, tr(context, 'Schedule')),
            ),
            _buildHourlyTimeline(
              context,
              provider,
              cal,
              timedEvents,
              locale,
              accent,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEventPage()),
        ),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'Add event')),
      ),
    );
  }

  // ── Hourly timeline (spine + dots + events) ──────────────────────────
  Widget _buildHourlyTimeline(
    BuildContext context,
    CalendarProvider provider,
    CalendarModel? cal,
    List<CalendarEvent> timedEvents,
    String locale,
    Color accent,
  ) {
    final format = cal == null ? '24h' : provider.getEffectiveTimeFormat(cal);
    final sunrise = provider.sunriseHour;
    final showSeconds = provider.showSeconds;
    final isToday = _isToday(_currentDate);
    final currentHour = DateTime.now().hour;

    final slots = _hourSlotsFor(format, sunrise);
    final eventsByHour = <int, List<CalendarEvent>>{};
    for (final e in timedEvents) {
      final h = int.tryParse(e.time.split(':').first) ?? 0;
      eventsByHour.putIfAbsent(h, () => []).add(e);
    }

    final widgets = <Widget>[];
    if (timedEvents.isEmpty) {
      widgets.add(_freeDayNote(context, accent));
    }

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final events = eventsByHour[slot.actualHour] ?? const <CalendarEvent>[];
      final isCurrent = isToday && slot.actualHour == currentHour;
      widgets.add(_hourSlotRow(
        context: context,
        slot: slot,
        events: events,
        provider: provider,
        cal: cal,
        format: format,
        sunrise: sunrise,
        locale: locale,
        accent: accent,
        showSeconds: showSeconds,
        isCurrent: isCurrent,
        isFirst: i == 0,
        isLast: i == slots.length - 1,
      ));
    }

    return SliverList(
      delegate: SliverChildListDelegate(widgets),
    );
  }

  List<_HourSlot> _hourSlotsFor(String format, int sunrise) {
    final slots = <_HourSlot>[];

    if (format == 'biblical') {
      for (int i = 0; i < 12; i++) {
        final h = (sunrise + i) % 24;
        slots.add(_HourSlot(
          actualHour: h,
          label: _ordinalHour(i + 1),
          subLabel: '${h.toString().padLeft(2, '0')}:00',
        ));
      }
      for (int i = 0; i < 12; i++) {
        final h = (sunrise + 12 + i) % 24;
        slots.add(_HourSlot(
          actualHour: h,
          label: _ordinalHour(i + 1),
          subLabel: '${h.toString().padLeft(2, '0')}:00',
          isNight: true,
        ));
      }
      return slots;
    }

    for (int h = 0; h < 24; h++) {
      slots.add(_HourSlot(
        actualHour: h,
        label: _hourLabel(h, format, sunrise),
        subLabel: null,
        isNight: h < sunrise || h >= sunrise + 12,
      ));
    }
    return slots;
  }

  String _ordinalHour(int n) {
    if (n == 1) return '1st hour';
    if (n == 2) return '2nd hour';
    if (n == 3) return '3rd hour';
    return '${n}th hour';
  }

  Widget _hourSlotRow({
    required BuildContext context,
    required _HourSlot slot,
    required List<CalendarEvent> events,
    required CalendarProvider provider,
    required CalendarModel? cal,
    required String format,
    required int sunrise,
    required String locale,
    required Color accent,
    required bool showSeconds,
    required bool isCurrent,
    required bool isFirst,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final hasEvents = events.isNotEmpty;

    final spineColor = theme.dividerColor.withValues(alpha: 0.22);
    final spineX = _labelWidth + _spineWidth / 2 - 0.75;
    final dotSize = isCurrent ? 14.0 : (hasEvents ? 10.0 : 8.0);
    final dotColor = isCurrent
        ? accent
        : (hasEvents
            ? events.first.color
            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4) ??
                Colors.grey);

    // Build spine segments — start at first dot, end at last dot
    Widget spineSegment;
    if (isFirst && isLast) {
      spineSegment = const SizedBox.shrink();
    } else if (isFirst) {
      spineSegment = Positioned(
        top: _dotColumnTop + dotSize / 2,
        bottom: 0,
        left: spineX,
        child: Container(width: 1.5, color: spineColor),
      );
    } else if (isLast) {
      spineSegment = Positioned(
        top: 0,
        height: _dotColumnTop + dotSize / 2,
        left: spineX,
        child: Container(width: 1.5, color: spineColor),
      );
    } else {
      spineSegment = Positioned(
        top: 0,
        bottom: 0,
        left: spineX,
        child: Container(width: 1.5, color: spineColor),
      );
    }

    return Stack(
      children: [
        spineSegment,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hour label ──
            Container(
              width: _labelWidth,
              padding: const EdgeInsets.only(top: 10, right: 10),
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    slot.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCurrent ? 11.5 : 10.5,
                      fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent
                          ? accent
                          : theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: hasEvents ? 1.0 : 0.55),
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (slot.subLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        slot.subLabel!,
                        style: TextStyle(
                          fontSize: 8.5,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Dot column ──
            SizedBox(
              width: _spineWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: _dotColumnTop),
                child: Center(
                  child: _buildDot(
                    hasEvents: hasEvents,
                    color: dotColor,
                    isCurrent: isCurrent,
                    size: dotSize,
                  ),
                ),
              ),
            ),
            // ── Events / spacer ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: hasEvents
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isCurrent)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 2, bottom: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _nowPill(context, accent),
                              ),
                            ),
                          ...events.map((e) => _timelineEventCard(
                                context,
                                provider,
                                cal,
                                e,
                                locale,
                                accent,
                                format,
                                sunrise,
                                showSeconds,
                              )),
                        ],
                      )
                    : SizedBox(
                        height: isCurrent ? 24 : 22,
                        child: isCurrent
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: _nowPill(context, accent),
                              )
                            : null,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot({
    required bool hasEvents,
    required Color color,
    required bool isCurrent,
    required double size,
  }) {
    if (isCurrent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }
    if (hasEvents) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _nowPill(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            tr(context, 'Now').toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _freeDayNote(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(context,
                    'A free day. Add an event to make it count.'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────────
  Widget _hero({
    required BuildContext context,
    required Color accent,
    required bool isDark,
    required bool isToday,
    required int dayNumber,
    required String monthName,
    required int yearNumber,
    required String locale,
    required CalendarModel? secondaryCal,
    required int eventCount,
    required List<SpecialDay> specials,
  }) {
    final theme = Theme.of(context);
    final fg = isDark
        ? theme.textTheme.bodyLarge?.color ?? Colors.white
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(accent, const Color(0xFF0B1020), 0.72) ?? accent,
                  const Color(0xFF0B1020),
                ]
              : [accent, Color.lerp(accent, Colors.black, 0.32) ?? accent],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: fg),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (isToday) _pill(tr(context, 'Today'), fg),
                const SizedBox(width: 6),
                _glassIcon(
                  icon: Icons.today,
                  onTap: () => _jumpTo(DateTime.now()),
                  fg: fg,
                ),
                const SizedBox(width: 6),
                _glassIcon(
                  icon: Icons.swap_horiz,
                  fg: fg,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            EquivalentsPage(initialDate: _currentDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                _fmt('EEEE', locale).format(_currentDate).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.82),
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: fg,
                      fontSize: 60,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            '$yearNumber',
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.7),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Wrap(
                spacing: 7,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _metaChip(
                    Icons.event_note,
                    '$eventCount ${eventCount == 1 ? tr(context, 'Event') : tr(context, 'Events')}',
                    fg,
                  ),
                  if (secondaryCal != null)
                    _metaChip(
                      Icons.sync_alt,
                      () {
                        final s = CalendarMath.getCalendarDateInfo(
                            secondaryCal, _currentDate);
                        return '${s['day']} ${s['monthName']} ${s['year']}';
                      }(),
                      fg,
                    ),
                  ...specials.take(2).map(
                        (sd) => _metaChip(Icons.star_outline, sd.name, fg),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _glassIcon({
    required IconData icon,
    required VoidCallback onTap,
    required Color fg,
  }) =>
      Material(
        color: fg.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 17, color: fg),
          ),
        ),
      );

  Widget _metaChip(IconData icon, String label, Color fg) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Day strip ────────────────────────────────────────────────────────
  Widget _dayStrip(BuildContext context, String locale, Color accent) {
    final today = _dateOnly(DateTime.now());

    return SizedBox(
      height: 76,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _settleStrip();
          return false;
        },
        child: ListView.builder(
          controller: _stripController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: _stripPadding, vertical: 6),
          itemCount: _stripWindow * 2 + 1,
          itemExtent: _stripTileWidth,
          itemBuilder: (context, index) {
            final date = today.add(Duration(days: index - _stripWindow));
            final isSelected = date == _currentDate;
            final isToday = date == today;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _jumpTo(date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday && !isSelected
                        ? accent.withValues(alpha: 0.55)
                        : Colors.transparent,
                    width: 1.3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _fmt('EEE', locale).format(date).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white70
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? accent
                                : Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );

  // ── All day ──────────────────────────────────────────────────────────
  Widget _allDaySection(
      BuildContext context, List<CalendarEvent> events, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: events
            .map((event) => Material(
                  color: event.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 13, color: event.color),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 190),
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: event.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Event card ───────────────────────────────────────────────────────
  Widget _timelineEventCard(
    BuildContext context,
    CalendarProvider provider,
    CalendarModel? cal,
    CalendarEvent event,
    String locale,
    Color accent,
    String format,
    int sunrise,
    bool showSeconds,
  ) {
    final theme = Theme.of(context);
    final start = _formatTime(event.time, format, showSeconds, sunrise);
    final end = _formatTime(_endTime(event), format, showSeconds, sunrise);
    final native =
        _formatTime(event.time, cal?.timeFormat ?? '24h', false, sunrise);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border(left: BorderSide(color: event.color, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (event.reminderMinutesBefore != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$start — $end',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                if (cal != null && cal.timeFormat != format)
                  Text(
                    native,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
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
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  Color _hexColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      if (cleaned.length != 6) return const Color(0xFF8B82FF);
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B82FF);
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _hourLabel(int hour, String format, int sunriseHour) {
    if (format == 'biblical') {
      return CalendarMath.getBiblicalTime(hour, 0, sunriseHour: sunriseHour)
          .split('(')
          .first
          .trim();
    }
    if (format == '12h') {
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$h12 $ampm';
    }
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  String _endTime(CalendarEvent event) {
    final parts = event.time.split(':');
    final start = DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    final end = start.add(Duration(minutes: event.durationMinutes));
    return '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(
      String timeStr, String format, bool showSeconds, int sunriseHour) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (format == 'biblical') {
      return CalendarMath.getBiblicalTime(hour, minute,
          sunriseHour: sunriseHour);
    }
    if (format == '12h') {
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final sec = showSeconds ? ':00' : '';
      return '$h12:${minute.toString().padLeft(2, '0')}$sec $ampm';
    }
    final sec = showSeconds ? ':00' : '';
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}$sec';
  }
}

class _HourSlot {
  final int actualHour;
  final String label;
  final String? subLabel;
  final bool isNight;
  const _HourSlot({
    required this.actualHour,
    required this.label,
    this.subLabel,
    this.isNight = false,
  });
}

class _StripHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Color background;
  final Widget child;

  const _StripHeader({
    required this.height,
    required this.background,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant _StripHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}