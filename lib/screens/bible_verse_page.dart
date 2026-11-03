import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/tr.dart';

class BibleVersePage extends StatefulWidget {
  const BibleVersePage({super.key});

  @override
  State<BibleVersePage> createState() => _BibleVersePageState();
}

class _BibleVersePageState extends State<BibleVersePage> {
  final List<Map<String, String>> _verses = const [
    {
      'text':
          'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      'reference': 'John 3:16',
    },
    {
      'text': 'I can do all this through him who gives me strength.',
      'reference': 'Philippians 4:13',
    },
    {
      'text':
          'Trust in the Lord with all your heart and lean not on your own understanding.',
      'reference': 'Proverbs 3:5',
    },
    {
      'text': 'The Lord is my shepherd, I lack nothing.',
      'reference': 'Psalm 23:1',
    },
    {
      'text':
          'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      'reference': 'Joshua 1:9',
    },
  ];

  late Map<String, String> _currentVerse;

  @override
  void initState() {
    super.initState();
    _currentVerse = _verses[DateTime.now().day % _verses.length];
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Bible Verse')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${tr(context, 'Sharing')} ${_currentVerse['reference']}',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book,
                    size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text(
                  _currentVerse['text']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentVerse['reference']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _currentVerse =
                        _verses[DateTime.now().millisecond % _verses.length];
                  }),
                  icon: const Icon(Icons.refresh),
                  label: Text(tr(context, 'New Verse')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}