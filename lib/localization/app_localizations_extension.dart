import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String tr(String key, [List<String>? args]) {
    String text = l10n.translate(key);

    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }

    return text;
  }
}