import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

/// Simple rename-only editor for an existing calendar.
class EditCalendarPage extends StatefulWidget {
  final CalendarModel calendar;
  const EditCalendarPage({super.key, required this.calendar});

  @override
  State<EditCalendarPage> createState() => _EditCalendarPageState();
}

class _EditCalendarPageState extends State<EditCalendarPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calendar.name);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Edit Calendar')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextFormField(
            controller: _nameController,
            decoration:
                InputDecoration(labelText: tr(context, 'Calendar Name')),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final updated = CalendarModel(
                id: widget.calendar.id,
                name: _nameController.text,
                daysPerWeek: widget.calendar.daysPerWeek,
                dayNames: widget.calendar.dayNames,
                weeksPerMonth: widget.calendar.weeksPerMonth,
                monthsPerYear: widget.calendar.monthsPerYear,
                monthNames: widget.calendar.monthNames,
                yearStart: widget.calendar.yearStart,
                timeFormat: widget.calendar.timeFormat,
                dateFormat: widget.calendar.dateFormat,
                calendarType: widget.calendar.calendarType,
                yearStartMonth: widget.calendar.yearStartMonth,
                yearStartDay: widget.calendar.yearStartDay,
                leapYearRule: widget.calendar.leapYearRule,
                leapYearPattern: widget.calendar.leapYearPattern,
                monthLengths: widget.calendar.monthLengths,
                weekStartDay: widget.calendar.weekStartDay,
                dayStartTime: widget.calendar.dayStartTime,
                customDayStart: widget.calendar.customDayStart,
                timezone: widget.calendar.timezone,
                showSeconds: widget.calendar.showSeconds,
                showMilliseconds: widget.calendar.showMilliseconds,
                yearOffset: widget.calendar.yearOffset,
                colorHex: widget.calendar.colorHex,
                emoji: widget.calendar.emoji,
              );
              Provider.of<CalendarProvider>(context, listen: false)
                  .updateCalendar(updated);
              Navigator.pop(context);
            },
            child: Text(tr(context, 'Save Changes')),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}