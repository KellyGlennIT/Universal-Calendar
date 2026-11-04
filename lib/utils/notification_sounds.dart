import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show RawResourceAndroidNotificationSound, AndroidNotificationSound;

/// A selectable reminder sound.
///
/// Each tone maps to:
///   • a raw resource bundled in `android/app/src/main/res/raw/` (Android),
///   • a `.caf` sound bundled inside the app on iOS.
///
/// The resource name is what `flutter_local_notifications` expects as the
/// `sound` parameter, and it is also stored on the event so the reminder can
/// be restored after a reboot / reschedule.
class NotificationTone {
  /// Stable identifier persisted in the event JSON. Never change these.
  final String id;

  /// Android resource name (file name without extension in `res/raw`).
  final String resource;

  /// iOS bundled sound file name.
  final String iosSound;

  /// English label key — passed through `tr()` for French.
  final String label;

  /// Icon shown in pickers.
  final IconData icon;

  const NotificationTone({
    required this.id,
    required this.resource,
    required this.iosSound,
    required this.label,
    required this.icon,
  });
}

/// The built-in tone library.
///
/// `default` keeps the device's own notification sound so users who never
/// touch the setting hear exactly what the system normally plays.
const List<NotificationTone> notificationTones = [
  NotificationTone(
    id: 'default',
    resource: '',
    iosSound: 'default',
    label: 'System default',
    icon: Icons.notifications_active_outlined,
  ),
  NotificationTone(
    id: 'chime',
    resource: 'chime',
    iosSound: 'chime.caf',
    label: 'Soft chime',
    icon: Icons.music_note,
  ),
  NotificationTone(
    id: 'bell',
    resource: 'bell',
    iosSound: 'bell.caf',
    label: 'Bell',
    icon: Icons.notifications_none,
  ),
  NotificationTone(
    id: 'bells',
    resource: 'bells',
    iosSound: 'bells.caf',
    label: 'Church bells',
    icon: Icons.church_outlined,
  ),
  NotificationTone(
    id: 'beep',
    resource: 'beep',
    iosSound: 'beep.caf',
    label: 'Digital beep',
    icon: Icons.electric_bolt_outlined,
  ),
  NotificationTone(
    id: 'marimba',
    resource: 'marimba',
    iosSound: 'marimba.caf',
    label: 'Marimba',
    icon: Icons.piano_outlined,
  ),
  NotificationTone(
    id: 'harp',
    resource: 'harp',
    iosSound: 'harp.caf',
    label: 'Harp',
    icon: Icons.auto_awesome,
  ),
  NotificationTone(
    id: 'drum',
    resource: 'drum',
    iosSound: 'drum.caf',
    label: 'Drum',
    icon: Icons.timer_outlined,
  ),
  NotificationTone(
    id: 'birds',
    resource: 'birds',
    iosSound: 'birds.caf',
    label: 'Birds',
    icon: Icons.flutter_dash,
  ),
  NotificationTone(
    id: 'hallelujah',
    resource: 'hallelujah',
    iosSound: 'hallelujah.caf',
    label: 'Hallelujah',
    icon: Icons.celebration_outlined,
  ),
  NotificationTone(
    id: 'piano',
    resource: 'piano',
    iosSound: 'piano.caf',
    label: 'Piano',
    icon: Icons.music_video_outlined,
  ),
  NotificationTone(
    id: 'water',
    resource: 'water',
    iosSound: 'water.caf',
    label: 'Water drops',
    icon: Icons.water_drop_outlined,
  ),
];

/// Looks up a tone by its persisted [id]; falls back to the system default.
NotificationTone toneById(String? id) {
  if (id == null) return notificationTones.first;
  for (final tone in notificationTones) {
    if (tone.id == id) return tone;
  }
  return notificationTones.first;
}

/// Android sound resource name for [id], or `null` for the system default.
String? androidSoundFor(String? id) {
  final resource = toneById(id).resource;
  return resource.isEmpty ? null : resource;
}

/// [androidSoundFor] wrapped in the platform type the plugin expects, so the
/// system default falls through when no bundled resource exists.
AndroidNotificationSound? androidNotificationSoundFor(String? id) {
  final resource = androidSoundFor(id);
  return resource == null ? null : RawResourceAndroidNotificationSound(resource);
}

/// iOS sound filename for [id], or `null` for the system default.
String? iosSoundFor(String? id) {
  final sound = toneById(id).iosSound;
  return sound == 'default' ? null : sound;
}
