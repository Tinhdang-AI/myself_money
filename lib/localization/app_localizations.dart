import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language/language_vi.dart';
import 'language/language_en.dart';

class AppLocalizations {
  final Locale locale;
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  AppLocalizations(this.locale);

  // Danh sách các bản dịch
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': languageEn,
    'vi': languageVi,
  };

  // Lấy bản dịch theo khóa
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Danh sách các ngôn ngữ hỗ trợ
  static final List<Locale> supportedLocales = [
    Locale('vi', 'VN'),
    Locale('en', 'US'),
  ];

  // Lưu ngôn ngữ đã chọn
  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
  }

  // Lấy ngôn ngữ đã lưu
  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('languageCode') ?? 'vi';

    switch (languageCode) {
      case 'en':
        return Locale('en', 'US');
      case 'vi':
      default:
        return Locale('vi', 'VN');
    }
  }
}

// Lớp hỗ trợ Flutter để tải các bản dịch
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}