import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final settings = context.watch<SettingsProvider>();
    final s = lang.strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── APPEARANCE ──────────────────────────────────────────────────
            _SectionHeader(s.settingsAppearance),
            Card(
              child: Column(
                children: [
                  // Theme
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsTheme,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        SegmentedButton<AppThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: AppThemeMode.system,
                              label: Text(s.settingsThemeSystem),
                              icon: const Icon(Icons.brightness_auto, size: 16),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.light,
                              label: Text(s.settingsThemeLight),
                              icon: const Icon(Icons.light_mode, size: 16),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.dark,
                              label: Text(s.settingsThemeDark),
                              icon: const Icon(Icons.dark_mode, size: 16),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (v) =>
                              settings.setThemeMode(v.first),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Accent color
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsAccentColor,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: SettingsProvider.accentColors
                              .map((color) => _ColorSwatch(
                                    color: color,
                                    selected:
                                        settings.seedColor.toARGB32() == color.toARGB32(),
                                    onTap: () => settings.setSeedColor(color),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── GENERAL ──────────────────────────────────────────────────────
            _SectionHeader(s.settingsGeneral),
            Card(
              child: Column(
                children: [
                  // Date format
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsDateFormat,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _DateChip(
                              label: 'DD.MM.YYYY',
                              selected:
                                  settings.dateFormat == AppDateFormat.dmy,
                              onTap: () =>
                                  settings.setDateFormat(AppDateFormat.dmy),
                            ),
                            _DateChip(
                              label: 'MM/DD/YYYY',
                              selected:
                                  settings.dateFormat == AppDateFormat.mdy,
                              onTap: () =>
                                  settings.setDateFormat(AppDateFormat.mdy),
                            ),
                            _DateChip(
                              label: 'YYYY-MM-DD',
                              selected:
                                  settings.dateFormat == AppDateFormat.ymd,
                              onTap: () =>
                                  settings.setDateFormat(AppDateFormat.ymd),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Language
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsLanguage,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LanguageTile(
                                label: 'English',
                                flag: '🇬🇧',
                                selected: lang.language == AppLanguage.en,
                                onTap: () =>
                                    lang.setLanguage(AppLanguage.en),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LanguageTile(
                                label: 'Polski',
                                flag: '🇵🇱',
                                selected: lang.language == AppLanguage.pl,
                                onTap: () =>
                                    lang.setLanguage(AppLanguage.pl),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── ABOUT ────────────────────────────────────────────────────────
            _SectionHeader(s.settingsAbout),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/icon.png',
                              width: 56, height: 56),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MBGS',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text(s.settingsVersion,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      s.settingsBggCredit,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.settingsBuiltWith,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.8,
          )),
    );
  }
}

// ─── Color swatch ─────────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

// ─── Date format chip ─────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontFamily: 'monospace')),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

// ─── Language tile ────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
