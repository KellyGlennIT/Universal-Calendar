import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';
import 'event_detail_page.dart';

class EventSearchPage extends StatefulWidget {
  const EventSearchPage({super.key});

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<CalendarProvider>(context);
    final results = _query.isEmpty
        ? provider.events
        : provider.events
            .where((e) =>
                e.title.toLowerCase().contains(_query) ||
                e.notes.toLowerCase().contains(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Search Events')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: tr(context, 'Search events'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1F2E)
                    : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(tr(context, 'No events found'),
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final event = results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: event.color),
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      event.notes.isNotEmpty ? event.notes : event.time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}