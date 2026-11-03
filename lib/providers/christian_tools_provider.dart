import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_request.dart';
import '../models/gratitude_entry.dart';
import '../models/scripture_memory_item.dart';

/// Backs every feature on the Christian Tools page:
/// prayer requests, the gratitude journal, and scripture memory.
///
/// Persists each list separately to SharedPreferences so a single corrupt
/// list can be recovered without losing the others.
class ChristianToolsProvider extends ChangeNotifier {
  List<PrayerRequest> _prayerRequests = [];
  List<GratitudeEntry> _gratitudeEntries = [];
  List<ScriptureMemoryItem> _scriptureMemory = [];

  List<PrayerRequest> get prayerRequests => _prayerRequests;
  List<GratitudeEntry> get gratitudeEntries => _gratitudeEntries;
  List<ScriptureMemoryItem> get scriptureMemory => _scriptureMemory;

  ChristianToolsProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerJson = prefs.getString('prayer_requests');
    if (prayerJson != null) {
      _prayerRequests = (json.decode(prayerJson) as List)
          .map((e) => PrayerRequest.fromJson(e))
          .toList();
    }
    final gratitudeJson = prefs.getString('gratitude_entries');
    if (gratitudeJson != null) {
      _gratitudeEntries = (json.decode(gratitudeJson) as List)
          .map((e) => GratitudeEntry.fromJson(e))
          .toList();
    }
    final scriptureJson = prefs.getString('scripture_memory');
    if (scriptureJson != null) {
      _scriptureMemory = (json.decode(scriptureJson) as List)
          .map((e) => ScriptureMemoryItem.fromJson(e))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'prayer_requests',
        json.encode(_prayerRequests.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'gratitude_entries',
        json.encode(_gratitudeEntries.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'scripture_memory',
        json.encode(_scriptureMemory.map((e) => e.toJson()).toList()));
  }

  // ── Prayer requests ─────────────────────────────────────────────────────

  void addPrayerRequest(PrayerRequest r) {
    _prayerRequests.add(r);
    _saveData();
    notifyListeners();
  }

  void updatePrayerRequest(PrayerRequest r) {
    final i = _prayerRequests.indexWhere((x) => x.id == r.id);
    if (i != -1) {
      _prayerRequests[i] = r;
      _saveData();
      notifyListeners();
    }
  }

  void togglePrayerAnswered(String id) {
    final i = _prayerRequests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _prayerRequests[i].answered = !_prayerRequests[i].answered;
      _saveData();
      notifyListeners();
    }
  }

  void deletePrayerRequest(String id) {
    _prayerRequests.removeWhere((r) => r.id == id);
    _saveData();
    notifyListeners();
  }

  // ── Gratitude journal ───────────────────────────────────────────────────

  void addGratitudeEntry(GratitudeEntry e) {
    _gratitudeEntries.add(e);
    _saveData();
    notifyListeners();
  }

  void deleteGratitudeEntry(String id) {
    _gratitudeEntries.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  // ── Scripture memory ────────────────────────────────────────────────────

  void addScriptureMemory(ScriptureMemoryItem i) {
    _scriptureMemory.add(i);
    _saveData();
    notifyListeners();
  }

  void toggleScriptureMemorized(String id) {
    final i = _scriptureMemory.indexWhere((s) => s.id == id);
    if (i != -1) {
      _scriptureMemory[i].memorized = !_scriptureMemory[i].memorized;
      _saveData();
      notifyListeners();
    }
  }

  void deleteScriptureMemory(String id) {
    _scriptureMemory.removeWhere((s) => s.id == id);
    _saveData();
    notifyListeners();
  }
}