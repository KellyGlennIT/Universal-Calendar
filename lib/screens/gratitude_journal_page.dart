import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gratitude_entry.dart';
import '../providers/christian_tools_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Journal of gratitude entries, newest first.
class GratitudeJournalPage extends StatelessWidget {
  const GratitudeJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<ChristianToolsProvider>(context);
    final entries = List<GratitudeEntry>.from(provider.gratitudeEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Gratitude Journal')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(tr(context, 'No entries yet')),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'Add Gratitude Entry'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final e = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.favorite, color: Colors.redAccent),
                    title: Text(e.text),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(e.date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          provider.deleteGratitudeEntry(e.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, provider),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _add(BuildContext context, ChristianToolsProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Add Gratitude Entry')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr(context, 'Description'),
                hintText: tr(context, 'Add details or reminders...'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['😊', '😄', '😌', '🥰']
                  .map((emoji) => GestureDetector(
                        onTap: () {
                          provider.addGratitudeEntry(GratitudeEntry(
                            id: CalendarMath.generateId(),
                            text: controller.text,
                            date: DateTime.now(),
                          ));
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 30)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Cancel')),
          ),
        ],
      ),
    );
  }
}