import 'package:flutter/material.dart';

/// The very first frame the user sees while the locale loads from disk.
///
/// Kept intentionally minimal: gradient background, glowing calendar icon,
/// slim spinner. No text — the app name appears immediately after on the
/// language picker.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E17), Color(0xFF171D2B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B82FF).withValues(alpha: 0.35),
                      const Color(0xFF63C7C2).withValues(alpha: 0.20),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B82FF).withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}