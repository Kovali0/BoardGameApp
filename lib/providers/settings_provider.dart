import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum AppDateFormat { dmy, mdy, ymd }

enum AppCurrency { pln, eur, usd, gbp }

enum AppPriceSearch { google, amazon, ceneo }

class SettingsProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  Color _seedColor = const Color(0xFF8B4513);
  AppDateFormat _dateFormat = AppDateFormat.dmy;
  AppCurrency _currency = AppCurrency.pln;
  AppPriceSearch _priceSearch = AppPriceSearch.google;
  List<String> _defaultPlayers = [];
  bool _timerFeedbackEnabled = true;

  // ─── 6 preset accent colors ───────────────────────────────────────────────
  static const List<Color> accentColors = [
    Color(0xFF8B4513), // Mahogany (default)
    Color(0xFF512DA8), // Deep Purple
    Color(0xFF2E7D32), // Forest Green
    Color(0xFF1976D2), // Ocean Blue
    Color(0xFFC62828), // Crimson
    Color(0xFFF57F17), // Gold
  ];

  // ─── Getters ──────────────────────────────────────────────────────────────
  AppThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  AppDateFormat get dateFormat => _dateFormat;
  AppCurrency get currency => _currency;
  AppPriceSearch get priceSearch => _priceSearch;
  List<String> get defaultPlayers => List.unmodifiable(_defaultPlayers);
  bool get timerFeedbackEnabled => _timerFeedbackEnabled;

  String get currencySymbol => switch (_currency) {
    AppCurrency.pln => 'zł',
    AppCurrency.eur => '€',
    AppCurrency.usd => '\$',
    AppCurrency.gbp => '£',
  };

  String get currencyCode => switch (_currency) {
    AppCurrency.pln => 'PLN',
    AppCurrency.eur => 'EUR',
    AppCurrency.usd => 'USD',
    AppCurrency.gbp => 'GBP',
  };

  ThemeMode get flutterThemeMode => switch (_themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light  => ThemeMode.light,
    AppThemeMode.dark   => ThemeMode.dark,
  };

  // ─── Date formatting ──────────────────────────────────────────────────────
  String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return switch (_dateFormat) {
      AppDateFormat.dmy => '$d.$m.$y',
      AppDateFormat.mdy => '$m/$d/$y',
      AppDateFormat.ymd => '$y-$m-$d',
    };
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode = switch (prefs.getString('theme_mode') ?? 'system') {
      'light' => AppThemeMode.light,
      'dark'  => AppThemeMode.dark,
      _       => AppThemeMode.system,
    };

    final colorValue = prefs.getInt('seed_color');
    if (colorValue != null) _seedColor = Color(colorValue & 0xFFFFFFFF);

    _dateFormat = switch (prefs.getString('date_format') ?? 'dmy') {
      'mdy' => AppDateFormat.mdy,
      'ymd' => AppDateFormat.ymd,
      _     => AppDateFormat.dmy,
    };

    _priceSearch = switch (prefs.getString('price_search') ?? 'google') {
      'amazon' => AppPriceSearch.amazon,
      'ceneo'  => AppPriceSearch.ceneo,
      _        => AppPriceSearch.google,
    };

    _currency = switch (prefs.getString('currency') ?? 'pln') {
      'eur' => AppCurrency.eur,
      'usd' => AppCurrency.usd,
      'gbp' => AppCurrency.gbp,
      _     => AppCurrency.pln,
    };

    _defaultPlayers = prefs.getStringList('default_players') ?? [];
    _timerFeedbackEnabled = prefs.getBool('timer_feedback') ?? true;

    notifyListeners();
  }

  // ─── Setters ──────────────────────────────────────────────────────────────
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      AppThemeMode.light  => 'light',
      AppThemeMode.dark   => 'dark',
      AppThemeMode.system => 'system',
    });
  }

  Future<void> setSeedColor(Color color) async {
    if (_seedColor.toARGB32() == color.toARGB32()) return;
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.toARGB32());
  }

  Future<void> setDateFormat(AppDateFormat format) async {
    if (_dateFormat == format) return;
    _dateFormat = format;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', switch (format) {
      AppDateFormat.mdy => 'mdy',
      AppDateFormat.ymd => 'ymd',
      AppDateFormat.dmy => 'dmy',
    });
  }

  Future<void> addDefaultPlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _defaultPlayers.contains(trimmed)) return;
    _defaultPlayers = [..._defaultPlayers, trimmed];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('default_players', _defaultPlayers);
  }

  Future<void> removeDefaultPlayer(String name) async {
    _defaultPlayers = _defaultPlayers.where((p) => p != name).toList();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('default_players', _defaultPlayers);
  }

  Future<void> setPriceSearch(AppPriceSearch engine) async {
    if (_priceSearch == engine) return;
    _priceSearch = engine;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('price_search', switch (engine) {
      AppPriceSearch.amazon => 'amazon',
      AppPriceSearch.ceneo  => 'ceneo',
      AppPriceSearch.google => 'google',
    });
  }

  Future<void> setCurrency(AppCurrency currency) async {
    if (_currency == currency) return;
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', switch (currency) {
      AppCurrency.eur => 'eur',
      AppCurrency.usd => 'usd',
      AppCurrency.gbp => 'gbp',
      AppCurrency.pln => 'pln',
    });
  }

  Future<void> setTimerFeedbackEnabled(bool value) async {
    if (_timerFeedbackEnabled == value) return;
    _timerFeedbackEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_feedback', value);
  }
}
