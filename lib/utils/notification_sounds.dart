import 'package:flutter/material.dart';

/// A selectable alarm tone for calendar alarms.
///
/// In the Alarm Clock model, tones map to:
///   • asset path: `assets/sounds/<resource>.wav`
///   • an audio asset that loops continuously with high priority / alarm volume
///     until the user dismisses or snoozes the alarm.
class AlarmTone {
  /// Stable identifier persisted in the event JSON (`reminderSound` or `alarmSound`).
  final String id;

  /// Wave file name without extension in `assets/sounds/`. Empty for system/default tone.
  final String resource;

  /// English label key — passed through `tr()` for French.
  final String label;

  /// Icon shown in tone pickers.
  final IconData icon;

  const AlarmTone({
    required this.id,
    required this.resource,
    required this.label,
    required this.icon,
  });

  /// Flutter asset path for the audio file (e.g. `assets/sounds/chime.wav`).
  /// If resource is empty, uses `assets/sounds/beep.wav` as the standard loud alarm fallback.
  String get assetPath => resource.isEmpty
      ? 'assets/sounds/beep.wav'
      : 'assets/sounds/$resource.wav';
}

/// The built-in alarm tone library.
const List<AlarmTone> alarmTones = [
  AlarmTone(
    id: 'default',
    resource: 'beep',
    label: 'Standard Alarm',
    icon: Icons.alarm,
  ),
  AlarmTone(
    id: 'chime',
    resource: 'chime',
    label: 'Soft chime',
    icon: Icons.music_note,
  ),
  AlarmTone(
    id: 'bell',
    resource: 'bell',
    label: 'Bell',
    icon: Icons.notifications_none,
  ),
  AlarmTone(
    id: 'bells',
    resource: 'bells',
    label: 'Church bells',
    icon: Icons.church_outlined,
  ),
  AlarmTone(
    id: 'beep',
    resource: 'beep',
    label: 'Digital beep',
    icon: Icons.electric_bolt_outlined,
  ),
  AlarmTone(
    id: 'marimba',
    resource: 'marimba',
    label: 'Marimba',
    icon: Icons.piano_outlined,
  ),
  AlarmTone(
    id: 'harp',
    resource: 'harp',
    label: 'Harp',
    icon: Icons.auto_awesome,
  ),
  AlarmTone(
    id: 'drum',
    resource: 'drum',
    label: 'Drum',
    icon: Icons.timer_outlined,
  ),
  AlarmTone(
    id: 'birds',
    resource: 'birds',
    label: 'Birds',
    icon: Icons.flutter_dash,
  ),
  AlarmTone(
    id: 'hallelujah',
    resource: 'hallelujah',
    label: 'Hallelujah',
    icon: Icons.celebration_outlined,
  ),
  AlarmTone(
    id: 'piano',
    resource: 'piano',
    label: 'Piano',
    icon: Icons.music_video_outlined,
  ),
  AlarmTone(
    id: 'water',
    resource: 'water',
    label: 'Water drops',
    icon: Icons.water_drop_outlined,
  ),
];

/// Backward compatibility alias
typedef NotificationTone = AlarmTone;
const List<AlarmTone> notificationTones = alarmTones;

/// Looks up an alarm tone by its persisted [id]; falls back to the default alarm.
AlarmTone toneById(String? id) {
  if (id == null) return alarmTones.first;
  for (final tone in alarmTones) {
    if (tone.id == id) return tone;
  }
  return alarmTones.first;
}

/// Returns the asset path to load in the audio player or alarm service.
String alarmAssetPathFor(String? id) => toneById(id).assetPath;
