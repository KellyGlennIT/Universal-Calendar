import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';
import '../l10n/tr.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _handleEnable(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final granted = await CalendarNotificationService.requestPermission();
    await locale.markNotificationsAsked();

    if (!context.mounted) return;

    if (granted) {
      // Fire a real notification using the default-sound channel so the
      // user hears the tone immediately — and you get instant proof that
      // sound is routing correctly.
      await CalendarNotificationService.sendTestNotification();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr(context, 'Notifications enabled')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Denied path — explain and offer to open Settings.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Notifications are off')),
        content: Text(tr(
          ctx,
          'You can turn notifications back on later in your device settings. Without them, your reminders will not ring.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(ctx, 'Later')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
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
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          const Color(0xFF8B82FF).withValues(alpha: 0.35),
                          const Color(0xFF63C7C2).withValues(alpha: 0.25),
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B82FF)
                                .withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_active,
                          size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      tr(context, 'Never miss a moment'),
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
                      tr(context,
                          'Allow notifications so your calendar reminders can ring with sound and vibration at the right time.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB0B0C0),
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleEnable(context),
                        icon: const Icon(Icons.notifications_active, size: 20),
                        label: Text(tr(context, 'Enable notifications')),
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
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          await context
                              .read<LocaleProvider>()
                              .markNotificationsAsked();
                        },
                        child: Text(
                          tr(context, 'Not now'),
                          style: const TextStyle(
                              color: Color(0xFFB0B0C0), fontSize: 15),
                        ),
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