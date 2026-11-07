import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../l10n/tr.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _handleEnable(BuildContext context) async {
    final granted = await CalendarAlarmService.requestPermission();
    if (!context.mounted) return;

    if (granted) {
      Navigator.pop(context, true);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(dialogContext, 'Alarms are off')),
        content: Text(tr(
          dialogContext,
          'Allow notifications and Alarms & reminders access in system settings. Without exact-alarm access, Android may deliver reminders late.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(dialogContext, 'Later')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await CalendarAlarmService.openSystemAppSettings();
            },
            child: Text(tr(dialogContext, 'Open settings')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E17), Color(0xFF171D2B), Color(0xFF0F1420)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        tooltip: tr(context, 'Back'),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          const Color(0xFF8B82FF).withValues(alpha: 0.35),
                          const Color(0xFF63C7C2).withValues(alpha: 0.25),
                        ]),
                      ),
                      child: const Icon(Icons.alarm_on,
                          size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      tr(context, 'Enable event alarms'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        context,
                        'Allow notifications and exact alarm access so this event reminder can ring close to its scheduled time. Without exact-alarm access, Android may deliver it late. A standard notification is used; lock-screen display and sound can also depend on device settings.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB0B0C0),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleEnable(context),
                        icon: const Icon(Icons.alarm, size: 20),
                        label: Text(tr(context, 'Enable event alarms')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B82FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        tr(context, 'Not now'),
                        style: const TextStyle(
                            color: Color(0xFFB0B0C0), fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
