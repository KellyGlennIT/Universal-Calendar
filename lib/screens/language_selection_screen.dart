import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

/// First-launch language picker.
///
/// Shown once, before the user has chosen between English and French. The
/// selection is written to SharedPreferences immediately, so the app never
/// shows this screen again unless the user resets all data.
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

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
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            color: const Color(0xFF8B82FF).withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.calendar_month,
                          size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Universal Calendar',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose your language\nChoisissez votre langue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB0B0C0),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _LanguageCard(
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: 'Continue in English',
                      onTap: () =>
                          context.read<LocaleProvider>().setLanguage('en'),
                    ),
                    const SizedBox(height: 14),
                    _LanguageCard(
                      flag: '🇫🇷',
                      title: 'Français',
                      subtitle: 'Continuer en français',
                      onTap: () =>
                          context.read<LocaleProvider>().setLanguage('fr'),
                    ),
                    const Spacer(),
                    const Text(
                      'Version 3.0',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4A4A5A)),
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

/// One language option in the picker.
///
/// Uses Material's ink ripple for press feedback. The whole card is a tap
/// target (22px padding) — no tiny touch zones.
class _LanguageCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B82FF).withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF707080),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Color(0xFF8B82FF)),
            ],
          ),
        ),
      ),
    );
  }
}