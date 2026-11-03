import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

/// Countdown timer with preset durations and haptic feedback on completion.
class PrayerTimerPage extends StatefulWidget {
  const PrayerTimerPage({super.key});

  @override
  State<PrayerTimerPage> createState() => _PrayerTimerPageState();
}

class _PrayerTimerPageState extends State<PrayerTimerPage> {
  int _seconds = 60;
  bool _running = false;
  int _remaining = 60;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Prayer Timer')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _running ? 1 - (_remaining / _seconds) : 0,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor),
                    ),
                    Center(
                      child: Text(
                        '${(_remaining ~/ 60).toString().padLeft(2, '0')}:'
                        '${(_remaining % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(
                    label: Text(tr(context, '1 min')),
                    onPressed: () => _setTimer(60)),
                ActionChip(
                    label: Text(tr(context, '5 min')),
                    onPressed: () => _setTimer(300)),
                ActionChip(
                    label: Text(tr(context, '10 min')),
                    onPressed: () => _setTimer(600)),
                ActionChip(
                    label: Text(tr(context, '15 min')),
                    onPressed: () => _setTimer(900)),
              ]),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_running) {
                    setState(() => _running = false);
                  } else {
                    setState(() {
                      _running = true;
                      _remaining = _seconds;
                      _startTimer();
                    });
                  }
                },
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setTimer(int seconds) {
    setState(() {
      _seconds = seconds;
      _remaining = seconds;
      _running = false;
    });
  }

  void _startTimer() async {
    while (_running && _remaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _running) {
        setState(() => _remaining--);
      }
    }
    if (_remaining == 0) {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _running = false);
    }
  }
}