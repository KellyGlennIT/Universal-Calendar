import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';
import 'bible_verse_page.dart';
import 'fasting_tracker_page.dart';
import 'gratitude_journal_page.dart';
import 'prayer_requests_page.dart';
import 'prayer_timer_page.dart';
import 'scripture_memory_page.dart';

/// Grid of every Christian tool in the app.
class ChristianToolsPage extends StatelessWidget {
  const ChristianToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final tools = <_ToolData>[
      _ToolData(
        icon: Icons.favorite,
        title: tr(context, 'Prayer Requests'),
        color: Colors.redAccent,
        page: const PrayerRequestsPage(),
      ),
      _ToolData(
        icon: Icons.auto_stories,
        title: tr(context, 'Bible Verse'),
        color: Colors.blueAccent,
        page: const BibleVersePage(),
      ),
      _ToolData(
        icon: Icons.timer,
        title: tr(context, 'Fasting Tracker'),
        color: Colors.orangeAccent,
        page: const FastingTrackerPage(),
      ),
      _ToolData(
        icon: Icons.book,
        title: tr(context, 'Gratitude Journal'),
        color: Colors.greenAccent,
        page: const GratitudeJournalPage(),
      ),
      _ToolData(
        icon: Icons.timer_outlined,
        title: tr(context, 'Prayer Timer'),
        color: Colors.purpleAccent,
        page: const PrayerTimerPage(),
      ),
      _ToolData(
        icon: Icons.memory,
        title: tr(context, 'Scripture Memory'),
        color: Colors.tealAccent,
        page: const ScriptureMemoryPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Christian Tools')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) => _ToolCard(tool: tools[index]),
      ),
    );
  }
}

class _ToolData {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;
  const _ToolData({
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolData tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tool.page),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(tool.icon, size: 28, color: tool.color),
              ),
              const SizedBox(height: 10),
              Text(
                tool.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}