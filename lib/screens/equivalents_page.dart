import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Shows the same real-world date expressed in every user calendar.
class EquivalentsPage extends StatefulWidget {
  final DateTime? initialDate;
  const EquivalentsPage({super.key, this.initialDate});

  @override
  State<EquivalentsPage> createState() => _EquivalentsPageState();
}

class _EquivalentsPageState extends State<EquivalentsPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<CalendarProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Date Equivalents')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text(
                    CalendarMath.formatDate(_selectedDate, 'DD/MM/YYYY'),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(tr(context, 'Tap calendar icon to change date'),
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text(tr(context, 'All Calendar Equivalents'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: provider.calendars.length,
                itemBuilder: (context, index) {
                  final cal = provider.calendars[index];
                  final data = CalendarMath.getEquivalents(
                      _selectedDate, [cal])[cal.name] ?? {};
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            cal.color.withValues(alpha: 0.2),
                        child: Text(cal.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(cal.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${tr(context, 'Date:')} ${data['date'] ?? tr(context, 'Unknown')}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${tr(context, 'Month:')} ${data['month'] ?? tr(context, 'Unknown')}  '
                            '${tr(context, 'Year:')} ${data['year'] ?? tr(context, 'Unknown')}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          if (data['isLeapYear'] != null)
                            Text(
                              '${tr(context, 'Leap Year:')} ${data['isLeapYear']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          if (data['monthCount'] != null)
                            Text(
                              '${tr(context, 'Total Months:')} ${data['monthCount']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () =>
                          _showDetails(context, cal.name, data),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(
      BuildContext context, String name, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${tr(context, 'Date:')} ${data['date'] ?? tr(context, 'Unknown')}'),
            const SizedBox(height: 4),
            Text(
                '${tr(context, 'Month:')} ${data['month'] ?? tr(context, 'Unknown')}'),
            const SizedBox(height: 4),
            Text(
                '${tr(context, 'Year:')} ${data['year'] ?? tr(context, 'Unknown')}'),
            const SizedBox(height: 4),
            Text(
                '${tr(context, 'Day:')} ${data['day'] ?? tr(context, 'Unknown')}'),
            if (data['isLeapYear'] != null) ...[
              const SizedBox(height: 4),
              Text('${tr(context, 'Leap Year:')} ${data['isLeapYear']}'),
            ],
            if (data['monthCount'] != null) ...[
              const SizedBox(height: 4),
              Text(
                  '${tr(context, 'Total Months:')} ${data['monthCount']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}