import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

/// Day-offset and year-offset calculator.
class OffsetCalculatorPage extends StatefulWidget {
  const OffsetCalculatorPage({super.key});

  @override
  State<OffsetCalculatorPage> createState() => _OffsetCalculatorPageState();
}

class _OffsetCalculatorPageState extends State<OffsetCalculatorPage> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 30));
  DateTime? _result;
  DateTime _targetDate = DateTime.now();
  bool _subtract = false;
  final _gregorianYearController =
      TextEditingController(text: '${DateTime.now().year}');
  final _calendarYearController =
      TextEditingController(text: '${DateTime.now().year}');
  int? _calculatedYearOffset;

  int get _difference => _to.difference(_from).inDays;

  Future<void> _pick(bool from) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(1),
      lastDate: DateTime(9999),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _gregorianYearController.dispose();
    _calendarYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final days = _difference.abs();

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Offset Calculator'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(
          tr(context,
              'Calculate the exact day offset between two dates, then move a date forward or backward by that amount.'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(tr(context, 'Start date')),
              subtitle: Text(DateFormat('EEEE, d MMMM y').format(_from)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pick(true),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.outlined_flag),
              title: Text(tr(context, 'End date')),
              subtitle: Text(DateFormat('EEEE, d MMMM y').format(_to)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => _pick(false),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Text(
              '$days',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              tr(context,
                  _difference < 0 ? 'days backward' : 'days forward'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 6),
            Text(
              '${days ~/ 7} ${tr(context, 'weeks')}${days % 7 == 0 ? '' : ' ${days % 7} ${tr(context, 'days')}'}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Text(tr(context, 'Apply an offset to another date'),
            style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          leading: const Icon(Icons.event),
          title: Text(tr(context, 'Date to adjust')),
          subtitle: Text(DateFormat('EEEE, d MMMM y').format(_targetDate)),
          trailing: const Icon(Icons.edit_calendar),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _targetDate,
              firstDate: DateTime(1),
              lastDate: DateTime(9999),
            );
            if (picked != null) {
              setState(() {
                _targetDate = picked;
                _result = null;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(context, 'Subtract instead of add')),
          value: _subtract,
          onChanged: (v) => setState(() => _subtract = v),
        ),
        FilledButton.icon(
          onPressed: () => setState(() {
            _result = _targetDate
                .add(Duration(days: _subtract ? -days : days));
          }),
          icon: const Icon(Icons.calculate),
          label: Text(tr(context, 'Apply offset to selected date')),
        ),
        if (_result != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(DateFormat('EEEE, d MMMM y').format(_result!)),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_result!)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: DateFormat('yyyy-MM-dd').format(_result!)));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr(context, 'Date copied'))));
                },
              ),
            ),
          ),
        const SizedBox(height: 28),
        Text(tr(context, 'Calculate a calendar year offset'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          tr(context,
              'Use this when your calendar year number differs from the Gregorian year. Offset = calendar year − Gregorian year.'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _gregorianYearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: tr(context, 'Gregorian year')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _calendarYearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: tr(context, 'Your calendar year')),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => setState(() {
            final g = int.tryParse(_gregorianYearController.text);
            final c = int.tryParse(_calendarYearController.text);
            _calculatedYearOffset = g == null || c == null ? null : c - g;
          }),
          icon: const Icon(Icons.functions),
          label: Text(tr(context, 'Calculate year offset')),
        ),
        if (_calculatedYearOffset != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.exposure),
              title: Text(
                  '${tr(context, 'Year offset:')} ${_calculatedYearOffset! >= 0 ? '+' : ''}$_calculatedYearOffset'),
              subtitle: Text(tr(context,
                  'Enter this value in the Year Offset field when creating your calendar.')),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: '$_calculatedYearOffset'));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr(context, 'Offset copied'))));
                },
              ),
            ),
          ),
      ]),
    );
  }
}