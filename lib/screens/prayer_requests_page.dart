import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prayer_request.dart';
import '../providers/christian_tools_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

class PrayerRequestsPage extends StatefulWidget {
  const PrayerRequestsPage({super.key});

  @override
  State<PrayerRequestsPage> createState() => _PrayerRequestsPageState();
}

class _PrayerRequestsPageState extends State<PrayerRequestsPage> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<ChristianToolsProvider>(context);
    final requests = provider.prayerRequests
        .where((r) =>
            r.title.toLowerCase().contains(_query) ||
            r.description.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Prayer Requests')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr(context, 'Search'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(tr(context, 'No prayer requests found')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            r.answered
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: r.answered ? Colors.green : Colors.grey,
                          ),
                          onPressed: () =>
                              provider.togglePrayerAnswered(r.id),
                        ),
                        title: Text(
                          r.title,
                          style: TextStyle(
                            decoration: r.answered
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: r.description.isEmpty
                            ? null
                            : Text(r.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              provider.deletePrayerRequest(r.id),
                        ),
                        onTap: () => _edit(context, provider, r),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, provider, null),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _edit(BuildContext context, ChristianToolsProvider provider,
      PrayerRequest? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? tr(context, 'Add') : tr(context, 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: tr(context, 'Title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  InputDecoration(labelText: tr(context, 'Description')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (existing == null) {
                provider.addPrayerRequest(PrayerRequest(
                  id: CalendarMath.generateId(),
                  title: titleController.text,
                  description: descController.text,
                  dateAdded: DateTime.now(),
                ));
              } else {
                existing.title = titleController.text;
                existing.description = descController.text;
                provider.updatePrayerRequest(existing);
              }
              Navigator.pop(context);
            },
            child: Text(tr(context, 'Save')),
          ),
        ],
      ),
    );
  }
}