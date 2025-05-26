import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale;

  // Update constructor to accept an initial locale
  LocaleProvider({required Locale initialLocale}) : _locale = initialLocale;

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;

    _locale = locale;
    AppLocalizations.saveLocale(locale.languageCode);
    notifyListeners();
  }

  Future<void> loadSavedLocale() async {
    _locale = await AppLocalizations.getLocale();
    notifyListeners();
  }
}
