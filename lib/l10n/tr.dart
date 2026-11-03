import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'french_strings.dart';

/// Translates [value] into the app's current language.
///
/// English is the base language — untranslated keys pass through unchanged.
/// French lookup goes through [frenchStrings].
///
/// Uses `listen: false` because translation is called during `build()` in
/// hundreds of widgets — subscribing to changes on every call would cause
/// every widget to rebuild on every language change. Instead, widgets that
/// need to react to language changes use `context.watch<LocaleProvider>()`
/// explicitly at the top of `build()`, which triggers one rebuild per widget
/// when the language changes.
String tr(BuildContext context, String value) {
  final language =
      Provider.of<LocaleProvider>(context, listen: false).languageCode;
  return language == 'fr' ? (frenchStrings[value] ?? value) : value;
}