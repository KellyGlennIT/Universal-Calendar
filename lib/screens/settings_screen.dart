import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../utils/calendar_presets.dart';
import '../l10n/tr.dart';
import 'calendar_explainer_page.dart';
import 'main_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<CalendarProvider>(context);

    final addedNames = provider.calendars.map((c) => c.name).toSet();
    final addedPresetCount =
        calendarPresets.values.where((p) => addedNames.contains(p.name)).length;
    final totalPresetCount = calendarPresets.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr(context, 'Settings')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, tr(context, 'Experience')),
          _card(
            context,
            icon: Icons.language,
            title: tr(context, 'Language'),
            subtitle:
                tr(context, 'Choose the language used throughout the app'),
            trailing: DropdownButton<String>(
              value: context.watch<LocaleProvider>().languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await context.read<LocaleProvider>().setLanguage(value);
                  provider.rescheduleReminders();
                }
              },
            ),
          ),
          _section(context, tr(context, 'Calendar Preferences')),
          _card(
            context,
            icon: Icons.calendar_today,
            title: tr(context, 'Primary Calendar'),
            subtitle: tr(context, 'Main calendar for display'),
            trailing: DropdownButton<String>(
              value: provider.primaryCalendarId.isEmpty
                  ? null
                  : provider.primaryCalendarId,
              hint: Text(tr(context, 'Select')),
              items: provider.calendars
                  .map((cal) =>
                      DropdownMenuItem(value: cal.id, child: Text(cal.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setPrimaryCalendar(value);
                  provider.selectCalendar(value);
                }
              },
            ),
          ),
          _card(
            context,
            icon: Icons.calendar_view_day,
            title: tr(context, 'Secondary Calendar'),
            subtitle: tr(context, 'Shown alongside primary'),
            trailing: DropdownButton<String?>(
              value: provider.secondaryCalendarId,
              hint: Text(tr(context, 'None')),
              items: [
                DropdownMenuItem(value: null, child: Text(tr(context, 'None'))),
                ...provider.calendars.map((cal) =>
                    DropdownMenuItem(value: cal.id, child: Text(cal.name))),
              ],
              onChanged: (value) => provider.setSecondaryCalendar(value),
            ),
          ),

          // ── Add a calendar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Add a calendar'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$addedPresetCount / $totalPresetCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context,
                        'Tap a calendar type to add it instantly. Calendars you already have appear with a checkmark.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (calendarPresets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(tr(context, 'No preset calendars available.'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: calendarPresets.entries.map((entry) {
                        final preset = entry.value;
                        final color = _hexToColor(preset.colorHex);
                        final isAdded = addedNames.contains(preset.name);
                        return FilterChip(
                          avatar: isAdded
                              ? Icon(Icons.check_circle, size: 16, color: color)
                              : Text(preset.emoji,
                                  style: const TextStyle(fontSize: 14)),
                          label: Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isAdded ? Colors.grey : color,
                              fontWeight:
                                  isAdded ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                          selected: isAdded,
                          showCheckmark: false,
                          backgroundColor: color.withValues(alpha: 0.10),
                          selectedColor: Colors.grey.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: isAdded
                                ? Colors.grey.withValues(alpha: 0.35)
                                : color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          onSelected: (_) {
                            if (isAdded) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${preset.name} — ${tr(context, 'already added')}'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final cal = provider.addPresetCalendar(entry.key);
                            if (cal != null && context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${tr(context, 'Added')} ${cal.name}'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.pushNamed(context, '/create_calendar'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Theme.of(context).primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(context, 'Create a custom calendar'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(context,
                                      'Design your own months, week length, and day names'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).primaryColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Time & Date ───────────────────────────────────────────────
          _section(context, tr(context, 'Time & Date')),
          _card(
            context,
            icon: Icons.access_time,
            title: tr(context, 'Time Format'),
            subtitle: tr(context, 'Used across the app'),
            trailing: DropdownButton<String?>(
              value: provider.globalTimeFormat,
              hint: Text(tr(context, 'Calendar default')),
              items: [
                DropdownMenuItem(
                    value: null, child: Text(tr(context, 'Calendar default'))),
                DropdownMenuItem(
                    value: '12h', child: Text(tr(context, '12-hour'))),
                DropdownMenuItem(
                    value: '24h', child: Text(tr(context, '24-hour'))),
                DropdownMenuItem(
                    value: 'biblical', child: Text(tr(context, 'Biblical'))),
              ],
              onChanged: (value) => provider.setGlobalTimeFormat(value),
            ),
          ),
          _card(
            context,
            icon: Icons.wb_sunny,
            title: tr(context, 'Sunrise Hour'),
            subtitle: tr(context, 'Start of first biblical hour'),
            trailing: DropdownButton<int>(
              value: provider.sunriseHour,
              items: const [
                DropdownMenuItem(value: 6, child: Text('6:00 AM')),
                DropdownMenuItem(value: 7, child: Text('7:00 AM')),
              ],
              onChanged: (value) {
                if (value != null) provider.setSunriseHour(value);
              },
            ),
          ),
          _switch(
            context,
            title: tr(context, 'Show Seconds'),
            subtitle: tr(context, 'Display seconds in times'),
            value: provider.showSeconds,
            onChanged: provider.setShowSeconds,
          ),
          _switch(
            context,
            title: tr(context, 'Day/Night Indicator'),
            subtitle: tr(context, 'Show sun/moon icons'),
            value: provider.showDayNight,
            onChanged: provider.setShowDayNight,
          ),

          // ── Alarms ────────────────────────────────────────────────────
          _section(context, tr(context, 'Alarms')),
          _card(
            context,
            icon: Icons.alarm_on,
            title: tr(context, 'Alarm permissions'),
            subtitle: tr(context,
                'Allow notifications and exact timing for event alarms'),
            onTap: () async {
              final granted = await CalendarAlarmService.requestPermission();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  granted
                      ? tr(context, 'Alarm permission granted')
                      : tr(context, 'Alarms are disabled in system settings'),
                ),
              ));
              if (granted) {
                provider.rescheduleReminders();
              }
            },
          ),
          _card(
            context,
            icon: Icons.volume_up_outlined,
            title: tr(context, 'Test alarm sound'),
            subtitle: tr(context,
                'Test looping alarm audio, vibration, and stop controls'),
            onTap: () async {
              final granted = await CalendarAlarmService.requestPermission();
              if (granted) {
                provider.rescheduleReminders();
                await CalendarAlarmService.sendTestNotification();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr(context,
                      'Enable alarm permissions in Android settings first')),
                ));
              }
            },
          ),

          // ── Storage / cleanup ─────────────────────────────────────────
          _section(context, tr(context, 'Storage')),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_delete_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr(context, 'Auto-delete old events'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context,
                        'Automatically remove events that ended more than the selected period ago. Keeps your calendar clean without manual deleting.'),
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: ValueKey(
                        'cleanup_${provider.autoCleanupDays ?? 'never'}'),
                    initialValue: provider.autoCleanupDays,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Delete after'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(tr(context, 'Never'))),
                      DropdownMenuItem(
                          value: 30, child: Text(tr(context, '30 days'))),
                      DropdownMenuItem(
                          value: 60, child: Text(tr(context, '60 days'))),
                      DropdownMenuItem(
                          value: 90, child: Text(tr(context, '90 days'))),
                      DropdownMenuItem(
                          value: 180, child: Text(tr(context, '180 days'))),
                      DropdownMenuItem(
                          value: 365, child: Text(tr(context, '1 year'))),
                    ],
                    onChanged: (v) async {
                      await provider.setAutoCleanupDays(v);
                      if (!context.mounted) return;
                      final count = v == null
                          ? 0
                          : await provider.deleteEventsOlderThan(v);
                      if (!context.mounted) return;
                      if (v != null && count > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$count ${tr(context, count == 1 ? 'event removed' : 'events removed')}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          _card(
            context,
            icon: Icons.delete_sweep_outlined,
            title: tr(context, 'Delete old events now'),
            subtitle: tr(context,
                'Runs the cleanup immediately with the current setting'),
            onTap: () async {
              final days = provider.autoCleanupDays;
              if (days == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr(context,
                      'Set an auto-delete period first, or choose Never to keep all events.')),
                ));
                return;
              }
              final count = await provider.deleteEventsOlderThan(days);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(count == 0
                    ? tr(context, 'Nothing to clean up')
                    : '$count ${tr(context, count == 1 ? 'event removed' : 'events removed')}'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),

          // ── Experience ────────────────────────────────────────────────
          _section(context, tr(context, 'Experience')),
          _card(
            context,
            icon: Icons.menu_book_outlined,
            title: tr(context, 'Calendar Guide'),
            subtitle: tr(context, 'Learn about each calendar in the app'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarExplainerPage()),
            ),
          ),
          _card(
            context,
            icon: Icons.explore_outlined,
            title: tr(context, 'Replay app tour'),
            subtitle: tr(context, 'A quick guide to the main features'),
            onTap: () => context
                .findAncestorStateOfType<MainScaffoldState>()
                ?.showFirstUseTour(force: true),
          ),

          // ── Data — NEW FILE-BASED BACKUP ──────────────────────────────
          _section(context, tr(context, 'Data')),
          _card(
            context,
            icon: Icons.ios_share_rounded,
            title: tr(context, 'Export backup'),
            subtitle:
                tr(context, 'Creates a .json file and opens the share sheet'),
            onTap: () async {
              try {
                final payload = provider.getBackupPayload();
                await BackupService.exportBackup(
                  payload,
                  subject: tr(context, 'Universal Calendar backup'),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${tr(context, 'Export failed')}: $e'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
          _card(
            context,
            icon: Icons.file_open_rounded,
            title: tr(context, 'Import backup'),
            subtitle: tr(context,
                'Picks a .json file and restores your calendars and events'),
            onTap: () => _importBackup(context, provider),
          ),
          _card(
            context,
            icon: Icons.restart_alt,
            title: tr(context, 'Reset All Data'),
            subtitle: tr(context, 'Delete all calendars and events'),
            onTap: () => _confirmReset(context, provider),
          ),
          _card(
            context,
            icon: Icons.info_outline,
            title: tr(context, 'About'),
            subtitle: 'Version 3.0',
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(tr(context, 'Universal Calendar')),
                content: Text(tr(context,
                    'A fully customizable calendar app with dual-calendar support and Christian tools.')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr(context, 'Close')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Import backup from file ────────────────────────────────────────
  Future<void> _importBackup(
      BuildContext context, CalendarProvider provider) async {
    // Confirm before wiping current data — restore replaces everything.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Restore from backup')),
        content: Text(tr(context,
            'This will replace all current calendars and events with the contents of the backup file. Continue?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'Restore')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final payload = await BackupService.pickAndReadBackup();
      if (payload == null) return; // user cancelled picker
      if (!context.mounted) return;

      final ok = await provider.restoreFromBackup(payload);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? tr(context, 'Backup restored')
            : tr(context, 'Invalid backup')),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(context, 'Invalid backup')),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Color _hexToColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      if (cleaned.length != 6) return const Color(0xFF8B82FF);
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF8B82FF);
    }
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _switch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(Icons.toggle_on, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _confirmReset(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Reset All Data')),
        content: Text(tr(context,
            'Are you sure you want to delete all calendars and events? This cannot be undone.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              await provider.resetAllData();
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr(context, 'Reset')),
          ),
        ],
      ),
    );
  }
}
