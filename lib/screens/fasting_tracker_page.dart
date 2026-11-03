import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

/// Date-range fasting tracker with progress bar.
class FastingTrackerPage extends StatefulWidget {
  const FastingTrackerPage({super.key});

  @override
  State<FastingTrackerPage> createState() => _FastingTrackerPageState();
}

class _FastingTrackerPageState extends State<FastingTrackerPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Fasting Tracker')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'Set your fasting period'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _dateCard(
                  context,
                  label: tr(context, 'Start date'),
                  date: _startDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateCard(
                  context,
                  label: tr(context, 'End date'),
                  date: _endDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(tr(context, '24 Hours'), const Duration(days: 1)),
              _chip(tr(context, '3 Days'), const Duration(days: 3)),
              _chip(tr(context, '7 Days'), const Duration(days: 7)),
            ]),
            const SizedBox(height: 20),
            if (_startDate != null && _endDate != null) ...[
              Text(
                '${tr(context, 'Days remaining:')} ${_endDate!.difference(DateTime.now()).inDays}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress(),
                minHeight: 10,
                backgroundColor: Colors.grey.shade800,
              ),
              const SizedBox(height: 4),
              Text(
                '${(_progress() * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Duration duration) => ActionChip(
        label: Text(label),
        onPressed: () {
          final now = DateTime.now();
          setState(() {
            _startDate = now;
            _endDate = now.add(duration);
          });
        },
      );

  Widget _dateCard(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                date == null
                    ? tr(context, 'Select')
                    : DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progress() {
    if (_startDate == null || _endDate == null) return 0;
    final total = _endDate!.difference(_startDate!).inDays;
    final elapsed = DateTime.now().difference(_startDate!).inDays;
    if (total <= 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}