import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

/// A single calendar's descriptive content.
class _CalendarInfo {
  final String emoji;
  final Color color;
  final String nameKey;
  final String tagline;
  final String origin;
  final String structure;
  final String leapYear;
  final String keyFacts;
  final String whenToUse;

  const _CalendarInfo({
    required this.emoji,
    required this.color,
    required this.nameKey,
    required this.tagline,
    required this.origin,
    required this.structure,
    required this.leapYear,
    required this.keyFacts,
    required this.whenToUse,
  });
}

/// The reference page that explains every calendar the app supports.
///
/// Responsive: single column on phones, two columns on tablets, three on
/// desktop. Each card expands to reveal the full explanation.
class CalendarExplainerPage extends StatelessWidget {
  const CalendarExplainerPage({super.key});

  List<_CalendarInfo> _infos(BuildContext context) => [
        _CalendarInfo(
          emoji: '📅',
          color: const Color(0xFF4DABF7),
          nameKey: 'Gregorian',
          tagline: tr(context, 'The international civil calendar'),
          origin: tr(context,
              'Introduced by Pope Gregory XIII in 1582 as a correction to the Julian calendar. Adopted worldwide within four centuries.'),
          structure: tr(context,
              '12 months. January, March, May, July, August, October, December have 31 days. April, June, September, November have 30. February has 28.'),
          leapYear: tr(context,
              'Every 4 years, except centuries not divisible by 400 (1700, 1800, 1900 are NOT leap; 2000 IS leap).'),
          keyFacts: tr(context,
              '• 365 or 366 days per year\n• Week starts Monday (or Sunday, configurable)\n• Day starts at midnight\n• Basis for ISO week numbers'),
          whenToUse: tr(context,
              'Default for business, government, and travel worldwide.'),
        ),
        _CalendarInfo(
          emoji: '🏛️',
          color: const Color(0xFFB197FC),
          nameKey: 'Julian',
          tagline: tr(context, 'The pre-1582 Roman calendar'),
          origin: tr(context,
              'Established by Julius Caesar in 45 BCE. Was the dominant European calendar for 1,600 years until the Gregorian reform.'),
          structure: tr(context,
              '12 months with the same names and lengths as Gregorian. February has 28 days in common years and 29 in leap years.'),
          leapYear: tr(context,
              'Every 4 years without exception. As a result, the calendar drifts 1 day every 128 years relative to the sun.'),
          keyFacts: tr(context,
              '• 365 or 366 days per year\n• Now 13 days behind Gregorian (1900–2100 CE)\n• Offset grows to 14 days in 2100\n• Still used by some Orthodox churches for liturgical feasts'),
          whenToUse: tr(context,
              'Liturgical calculations for Eastern Orthodox communities and historical research.'),
        ),
        _CalendarInfo(
          emoji: '🌍',
          color: const Color(0xFF51CF66),
          nameKey: 'Ethiopian',
          tagline: tr(context, 'The calendar of Ethiopia and Eritrea'),
          origin: tr(context,
              'Rooted in ancient Egyptian reckoning and the Alexandrian computus. Separate from Gregorian since the 4th century.'),
          structure: tr(context,
              '13 months: 12 of 30 days each, plus Pagume with 5 days (6 in leap years). 365 or 366 days total.'),
          leapYear: tr(context,
              'Every 4 years, when year mod 4 = 3. Pagume gains its 6th day in leap years.'),
          keyFacts: tr(context,
              '• 7–8 years behind Gregorian (currently 2018 EC = 2025/26 CE)\n• New Year (Enkutatash) on Sept 11 (or 12 in leap years)\n• Day starts at sunrise, not midnight\n• Named after saints on many days'),
          whenToUse: tr(context,
              'Ethiopian civic life, and churches and individuals honouring the ancient reckoning.'),
        ),
        _CalendarInfo(
          emoji: '⛪',
          color: const Color(0xFFCC5DE8),
          nameKey: 'Coptic',
          tagline: tr(context, 'The liturgical calendar of the Coptic Church'),
          origin: tr(context,
              'Anchored to August 29, 284 CE — the beginning of the Diocletian persecution, called the "Era of Martyrs."'),
          structure: tr(context,
              '13 months: 12 of 30 days each, plus Pi Kogi Enavot with 5 days (6 in leap years). Same structure as Ethiopian.'),
          leapYear: tr(context,
              'Every 4 years, when year mod 4 = 3. The 13th month absorbs the extra day.'),
          keyFacts: tr(context,
              '• Year 1743 AM corresponds to 2025/26 CE\n• New Year (Thout 1) on Sept 11 in Gregorian\n• Months: Thout, Paopi, Hathor, Koiak, Tobi, Meshir, Paremhat, Paremoude, Pashons, Paoni, Epip, Mesori, Pi Kogi Enavot\n• Same month names used in Ethiopian liturgical texts'),
          whenToUse: tr(context,
              'Coptic Orthodox feast dates and historical Coptic records.'),
        ),
        _CalendarInfo(
          emoji: '✡️',
          color: const Color(0xFFD4AF37),
          nameKey: 'Biblical',
          tagline: tr(context, 'The Hebrew lunisolar calendar'),
          origin: tr(context,
              'Ancient Hebrew reckoning, refined by Rabbinic scholars through the 1st millennium CE. Standardised in the Middle Ages.'),
          structure: tr(context,
              '12 months of 29 or 30 days in common years; 13 months in leap years (Adar I and Adar II are separated).'),
          leapYear: tr(context,
              '7 leap years in every 19-year cycle (years 3, 6, 8, 11, 14, 17, 19). An extra month is added, not an extra day.'),
          keyFacts: tr(context,
              '• Year 5786 corresponds to 2025/26 CE\n• Civil new year (Rosh Hashanah) in Tishri (Sept–Oct)\n• Religious new year (Nisan) in Spring\n• Day begins at sunset, not midnight\n• Months: Tishri, Cheshvan, Kislev, Tevet, Shevat, Adar, Nisan, Iyar, Sivan, Tammuz, Av, Elul'),
          whenToUse: tr(context,
              'Jewish religious life, biblical feast calculations, and Tanakh study.'),
        ),
        _CalendarInfo(
          emoji: '☪️',
          color: const Color(0xFF20C997),
          nameKey: 'Islamic',
          tagline: tr(context, 'The Hijri lunar calendar'),
          origin: tr(context,
              'Established at the Hijra — the migration of the Prophet Muhammad from Mecca to Medina in 622 CE.'),
          structure: tr(context,
              '12 lunar months of 29 or 30 days. A year is 354 or 355 days — about 11 days shorter than a solar year.'),
          leapYear: tr(context,
              '11 leap years per 30-year arithmetic cycle at positions 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29. In leap years Dhu al-Hijjah has 30 days instead of 29.'),
          keyFacts: tr(context,
              '• Year 1447 AH corresponds to 2025/26 CE\n• Months: Muharram, Safar, Rabi I, Rabi II, Jumada I, Jumada II, Rajab, Sha\'ban, Ramadan, Shawwal, Dhu al-Q\'dah, Dhu al-Hijjah\n• Tabular arithmetic (used by this app) — actual observance may differ by 1–2 days based on local moon sighting\n• Months drift through seasons: Ramadan falls 11 days earlier each year'),
          whenToUse: tr(context,
              'Islamic religious obligations, and daily reference for Muslims worldwide.'),
        ),
        _CalendarInfo(
          emoji: '🇫🇷',
          color: const Color(0xFFFF8787),
          nameKey: 'French Republican',
          tagline: tr(context, 'The calendar of the First French Republic'),
          origin: tr(context,
              'Created during the French Revolution. Epoch: 22 September 1792 — the proclamation of the Republic. In use 1793–1805.'),
          structure: tr(context,
              '12 months of 30 days each (360 days) plus 5 complementary days (sansculottides) at year end, 6 in leap years.'),
          leapYear: tr(context,
              'Romme rule: leap years at positions 3, 7, 11 of each 4-year cycle. The 6th complementary day is added in leap years.'),
          keyFacts: tr(context,
              '• Year 234 corresponds to 2025/26 CE\n• Months have seasonal names (Vendémiaire = vintage, Germinal = germination, Fructidor = fruit)\n• 10-day décades replace 7-day weeks\n• Every day has a specific name (an agricultural item, animal, or tool)'),
          whenToUse: tr(context,
              'Historical reenactment, French Revolutionary study, and academic interest.'),
        ),
        _CalendarInfo(
          emoji: '🛠️',
          color: const Color(0xFF8B82FF),
          nameKey: 'Custom',
          tagline: tr(context, 'Design your own calendar'),
          origin: tr(context,
              'Built from your own rules. Choose the number of months, the number of days in each month, the weekday names, and the year-start date.'),
          structure: tr(context,
              'Fully configurable: any number of months (1–20), any days per month (1–60), any weekday count (1–14).'),
          leapYear: tr(context,
              'Four rules available: none, every 4 years, Gregorian-style, or a custom position pattern (e.g. 3, 6, 8, 11, 14, 17, 19).'),
          keyFacts: tr(context,
              '• Perfect for fictional-world building\n• Supports non-standard weekday lengths\n• Can be backed up as JSON\n• Combine with a Year Offset to anchor your year numbering'),
          whenToUse: tr(context,
              'Fiction, tabletop RPGs, academic experiments, alternative timekeeping.'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final infos = _infos(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Calendar Guide')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isMedium = constraints.maxWidth >= 600 && !isWide;
          final horizontal = isWide ? 32.0 : (isMedium ? 24.0 : 16.0);
          final maxCardWidth = isWide ? 380.0 : (isMedium ? 340.0 : 500.0);

          return ListView(
            padding: EdgeInsets.all(horizontal),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.public,
                              color: Theme.of(context).primaryColor,
                              size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr(context, 'Calendar Guide'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  tr(context,
                                      'Learn the origin, structure, and use of every calendar this app supports.'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: infos.map((info) {
                  return SizedBox(
                    width: maxCardWidth,
                    child: _CalendarInfoCard(info: info),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    tr(context,
                        'Dates shown are approximate for historical calendars. Modern observance may vary by community.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

/// One expandable info card explaining a single calendar type.
class _CalendarInfoCard extends StatefulWidget {
  final _CalendarInfo info;
  const _CalendarInfoCard({required this.info});

  @override
  State<_CalendarInfoCard> createState() => _CalendarInfoCardState();
}

class _CalendarInfoCardState extends State<_CalendarInfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    info.color.withValues(alpha: 0.30),
                    info.color.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: info.color.withValues(alpha: 0.40)),
                  ),
                  alignment: Alignment.center,
                  child: Text(info.emoji,
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(context, info.nameKey),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                      const SizedBox(height: 2),
                      Text(info.tagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          )),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more,
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
              ]),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 14,
                      color:
                          Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr(context, 'Tap to read more'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ),
                ]),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(context, Icons.history_edu,
                        tr(context, 'Origin'), info.origin),
                    _section(context, Icons.view_agenda_outlined,
                        tr(context, 'Structure'), info.structure),
                    _section(context, Icons.calendar_today,
                        tr(context, 'Leap Year'), info.leapYear),
                    _section(context, Icons.star_outline,
                        tr(context, 'Key Facts'), info.keyFacts),
                    _section(context, Icons.check_circle_outline,
                        tr(context, 'When to Use'), info.whenToUse),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
      BuildContext context, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: widget.info.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.info.color,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      height: 1.45,
                    )),
          ),
        ],
      ),
    );
  }
}