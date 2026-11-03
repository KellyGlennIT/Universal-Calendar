import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scripture_memory_item.dart';
import '../providers/christian_tools_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/calendar_math.dart';
import '../l10n/tr.dart';

/// Scripture memory tracker with per-item reveal.
class ScriptureMemoryPage extends StatefulWidget {
  const ScriptureMemoryPage({super.key});

  @override
  State<ScriptureMemoryPage> createState() => _ScriptureMemoryPageState();
}

class _ScriptureMemoryPageState extends State<ScriptureMemoryPage> {
  /// Per-item reveal state — hiding one verse does not hide the rest.
  final Set<String> _revealed = {};

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final provider = Provider.of<ChristianToolsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Scripture Memory')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: provider.scriptureMemory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.memory, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(tr(context, 'No verses added')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.scriptureMemory.length,
              itemBuilder: (context, index) {
                final item = provider.scriptureMemory[index];
                final shown = _revealed.contains(item.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.reference),
                    subtitle: shown ? Text(item.verseText) : null,
                    leading: IconButton(
                      icon: Icon(
                        item.memorized
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color:
                            item.memorized ? Colors.green : Colors.grey,
                      ),
                      onPressed: () =>
                          provider.toggleScriptureMemorized(item.id),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(shown
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() {
                            if (shown) {
                              _revealed.remove(item.id);
                            } else {
                              _revealed.add(item.id);
                            }
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              provider.deleteScriptureMemory(item.id),
                        ),
                      ],
                    ),
                    onTap: () => setState(() {
                      if (shown) {
                        _revealed.remove(item.id);
                      } else {
                        _revealed.add(item.id);
                      }
                    }),
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
    final refController = TextEditingController();
    final verseController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, 'Add Verse to Memorize')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refController,
              decoration: InputDecoration(labelText: tr(context, 'Title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: verseController,
              decoration:
                  InputDecoration(labelText: tr(context, 'Verse Text')),
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
              provider.addScriptureMemory(ScriptureMemoryItem(
                id: CalendarMath.generateId(),
                reference: refController.text,
                verseText: verseController.text,
              ));
              Navigator.pop(context);
            },
            child: Text(tr(context, 'Save')),
          ),
        ],
      ),
    );
  }
}