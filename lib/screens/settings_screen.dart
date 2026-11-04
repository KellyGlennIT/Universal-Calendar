import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
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

    // ── Duplicate detection for the "Add a calendar" section ─────────────
    // A preset counts as "already added" when a calendar with the same
    // display name exists. Presets always ship with unique names, so this
    // catches the duplicate case reliably and stays out of the way for
    // calendars the user created manually.
    final addedNames = provider.calendars.map((c) => c.name).toSet();
    final addedPresetCount = calendarPresets.values
        .where((p) => addedNames.contains(p.name))
        .length;
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
                DropdownMenuItem(
                    value: null, child: Text(tr(context, 'None'))),
                ...provider.calendars.map((cal) =>
                    DropdownMenuItem(value: cal.id, child: Text(cal.name))),
              ],
              onChanged: (value) => provider.setSecondaryCalendar(value),
            ),
          ),
          // ── Add a calendar (advanced) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Add a calendar'),
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.12),
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
                      child: Text(
                        tr(context, 'No preset calendars available.'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          calendarPresets.entries.map((entry) {
                        final preset = entry.value;
                        final color = _hexToColor(preset.colorHex);
                        final isAdded =
                            addedNames.contains(preset.name);
                        return FilterChip(
                          avatar: isAdded
                              ? Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: color,
                                )
                              : Text(
                                  preset.emoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                          label: Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isAdded ? Colors.grey : color,
                              fontWeight: isAdded
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                          selected: isAdded,
                          showCheckmark: false,
                          backgroundColor:
                              color.withValues(alpha: 0.10),
                          selectedColor:
                              Colors.grey.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: isAdded
                                ? Colors.grey.withValues(alpha: 0.35)
                                : color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          onSelected: (_) {
                            if (isAdded) {
                              // Duplicate guard — tell the user why
                              // nothing happened instead of silently
                              // ignoring the tap.
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${preset.name} — '
                                    '${tr(context, 'already added')}',
                                  ),
                                  duration:
                                      const Duration(seconds: 2),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final cal = provider
                                .addPresetCalendar(entry.key);
                            if (cal != null && context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${tr(context, 'Added')} '
                                    '${cal.name}',
                                  ),
                                  duration:
                                      const Duration(seconds: 2),
                                  behavior:
                                      SnackBarBehavior.floating,
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
                  // ── Create custom calendar ───────────────────────
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pushNamed(
                        context, '/create_calendar'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(context,
                                      'Create a custom calendar'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(context,
                                      'Design your own months, week length, and day names'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── End add-calendar section ────────────────────────────────
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
                    value: null,
                    child: Text(tr(context, 'Calendar default'))),
                DropdownMenuItem(
                    value: '12h', child: Text(tr(context, '12-hour'))),
                DropdownMenuItem(
                    value: '24h', child: Text(tr(context, '24-hour'))),
                DropdownMenuItem(
                    value: 'biblical',
                    child: Text(tr(context, 'Biblical'))),
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
          _section(context, tr(context, 'Notifications')),
          _card(
            context,
            icon: Icons.notifications_active_outlined,
            title: tr(context, 'Allow notifications'),
            subtitle: tr(context,
                'Request permission for audible calendar alerts'),
            onTap: () async {
              final granted =
                  await CalendarNotificationService.requestPermission();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  granted
                      ? tr(context, 'Notification permission granted')
                      : tr(context,
                          'Notifications are disabled in system settings'),
                ),
              ));
              if (granted) {
                provider.rescheduleReminders();
                await CalendarNotificationService.sendTestNotification();
              }
            },
          ),
          _card(
            context,
            icon: Icons.volume_up_outlined,
            title: tr(context, 'Test notification sound'),
            subtitle: tr(context,
                'Send a test alert to verify delivery and sound'),
            onTap: () async {
              final granted =
                  await CalendarNotificationService.requestPermission();
              if (granted) {
                provider.rescheduleReminders();
                await CalendarNotificationService.sendTestNotification();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr(context,
                      'Enable notifications in Android settings first')),
                ));
              }
            },
          ),
          _section(context, tr(context, 'Experience')),
          _card(
            context,
            icon: Icons.menu_book_outlined,
            title: tr(context, 'Calendar Guide'),
            subtitle: tr(context, 'Learn about each calendar in the app'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalendarExplainerPage()),
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
          _section(context, tr(context, 'Data')),
          _card(
            context,
            icon: Icons.download_outlined,
            title: tr(context, 'Backup All Data'),
            subtitle:
                tr(context, 'Copy a full JSON backup to the clipboard'),
            onTap: () async {
              final payload = provider.getBackupPayload();
              final text =
                  const JsonEncoder.withIndent('  ').convert(payload);
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr(context, 'Backup copied to clipboard')),
                duration: const Duration(seconds: 3),
              ));
            },
          ),
          _card(
            context,
            icon: Icons.upload_outlined,
            title: tr(context, 'Restore from backup'),
            subtitle: tr(context, 'Paste a JSON backup to restore'),
            onTap: () => _showRestoreDialog(context, provider),
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
        secondary:
            Icon(Icons.toggle_on, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showRestoreDialog(
      BuildContext context, CalendarProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Restore from backup')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(context, 'Paste the backup JSON here'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '{ "calendars": [...], "events": [...] }',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final decoded = json.decode(controller.text);
                if (decoded is! Map) {
                  throw const FormatException('Not a JSON object');
                }
                final ok = await provider
                    .restoreFromBackup(Map<String, dynamic>.from(decoded));
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    ok
                        ? tr(context, 'Backup restored')
                        : tr(context, 'Invalid backup'),
                  ),
                ));
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tr(context, 'Invalid backup')),
                ));
              }
            },
            child: Text(tr(context, 'Restore')),
          ),
        ],
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