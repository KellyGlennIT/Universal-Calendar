import 'package:flutter/foundation.dart';

/// Tracks which bottom-level screen is currently visible.
///
/// 0 = Home, 1 = Calendars, 2 = Settings. The `MainScaffold` uses this to
/// drive its `IndexedStack` — each tab keeps its scroll position and state
/// alive across switches.
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// Switches the visible tab. Any negative index is clamped to 0 so callers
  /// can pass results from `indexOf()` without checking first.
  void setIndex(int index) {
    final safe = index < 0 ? 0 : index;
    if (safe == _currentIndex) return;
    _currentIndex = safe;
    notifyListeners();
  }
}