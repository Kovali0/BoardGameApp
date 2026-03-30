import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/export_service.dart';

// ignore_for_file: use_build_context_synchronously

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
                  const Divider(height: 1),
                  // Currency
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsCurrency,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _CurrencyChip(
                              label: 'PLN  zł',
                              selected: settings.currency == AppCurrency.pln,
                              onTap: () => settings.setCurrency(AppCurrency.pln),
                            ),
                            _CurrencyChip(
                              label: 'EUR  €',
                              selected: settings.currency == AppCurrency.eur,
                              onTap: () => settings.setCurrency(AppCurrency.eur),
                            ),
                            _CurrencyChip(
                              label: 'USD  \$',
                              selected: settings.currency == AppCurrency.usd,
                              onTap: () => settings.setCurrency(AppCurrency.usd),
                            ),
                            _CurrencyChip(
                              label: 'GBP  £',
                              selected: settings.currency == AppCurrency.gbp,
                              onTap: () => settings.setCurrency(AppCurrency.gbp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Price search engine
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.settingsPriceSearch,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _CurrencyChip(
                              label: '🌐  Google',
                              selected: settings.priceSearch == AppPriceSearch.google,
                              onTap: () => settings.setPriceSearch(AppPriceSearch.google),
                            ),
                            _CurrencyChip(
                              label: '📦  Amazon',
                              selected: settings.priceSearch == AppPriceSearch.amazon,
                              onTap: () => settings.setPriceSearch(AppPriceSearch.amazon),
                            ),
                            _CurrencyChip(
                              label: '🛒  Ceneo',
                              selected: settings.priceSearch == AppPriceSearch.ceneo,
                              onTap: () => settings.setPriceSearch(AppPriceSearch.ceneo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Timer feedback
                  SwitchListTile(
                    title: Text(s.settingsTimerFeedback),
                    subtitle: Text(s.settingsTimerFeedbackSub,
                        style: const TextStyle(fontSize: 12)),
                    value: settings.timerFeedbackEnabled,
                    onChanged: (v) => settings.setTimerFeedbackEnabled(v),
                    contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  ),
                  const Divider(height: 1),
                  // Default players
                  _DefaultPlayersTile(s: s, settings: settings),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── EXPORT ───────────────────────────────────────────────────────
            _SectionHeader(s.settingsExport),
            _ExportSection(),
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
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                final version =
                                    snapshot.data?.version ?? '—';
                                return Text(
                                  '${s.settingsVersion} $version',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                );
                              },
                            ),
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

// ─── Default players tile ─────────────────────────────────────────────────────

class _DefaultPlayersTile extends StatefulWidget {
  final dynamic s;
  final SettingsProvider settings;
  const _DefaultPlayersTile({required this.s, required this.settings});

  @override
  State<_DefaultPlayersTile> createState() => _DefaultPlayersTileState();
}

class _DefaultPlayersTileState extends State<_DefaultPlayersTile> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.settings.addDefaultPlayer(name);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final players = widget.settings.defaultPlayers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.settingsDefaultPlayers,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: s.settingsDefaultPlayersHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
                child: Text(s.settingsDefaultPlayersAdd),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            Text(s.settingsDefaultPlayersEmpty,
                style: const TextStyle(color: Colors.grey, fontSize: 13))
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: players
                  .map((name) => Chip(
                        label: Text(name),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            widget.settings.removeDefaultPlayer(name),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Currency chip ────────────────────────────────────────────────────────────

class _CurrencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CurrencyChip({
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

// ─── Export section ───────────────────────────────────────────────────────────

class _ExportSection extends StatefulWidget {
  const _ExportSection();

  @override
  State<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends State<_ExportSection> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    final s = context.read<LanguageProvider>().strings;
    setState(() => _loading = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.exportPreparing)));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final games = context.watch<GameProvider>().games;
    final sessions = context.watch<SessionProvider>().sessions;
    final wishlist = context.watch<WishlistProvider>().items;

    return Card(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Full backup ──
              _ExportTile(
                icon: Icons.data_object,
                title: s.exportFullJson,
                subtitle: s.exportFullJsonSub,
                onTap: _loading
                    ? null
                    : () => _run(() =>
                        ExportService.exportJson(games, sessions, wishlist)),
              ),
              const Divider(height: 1),
              _ExportTile(
                icon: Icons.folder_zip_outlined,
                title: s.exportFullZip,
                subtitle: s.exportFullZipSub,
                onTap: _loading
                    ? null
                    : () => _run(() =>
                        ExportService.exportZip(games, sessions, wishlist)),
              ),
              const Divider(height: 1),

              // ── Individual CSVs ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.exportIndividual,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ),
              ),
              _ExportTile(
                icon: Icons.sports_esports_outlined,
                title: s.exportSessions,
                subtitle: 'sessions.csv',
                onTap: _loading
                    ? null
                    : () => _run(
                        () => ExportService.exportSessionsCsv(sessions)),
              ),
              const Divider(height: 1),
              _ExportTile(
                icon: Icons.casino_outlined,
                title: s.exportCollection,
                subtitle: 'collection.csv',
                onTap: _loading
                    ? null
                    : () =>
                        _run(() => ExportService.exportCollectionCsv(games)),
              ),
              const Divider(height: 1),
              _ExportTile(
                icon: Icons.bookmark_outline,
                title: s.exportWishlist,
                subtitle: 'wishlist.csv',
                onTap: _loading
                    ? null
                    : () => _run(
                        () => ExportService.exportWishlistCsv(wishlist)),
              ),
              const Divider(height: 1),
              _ExportTile(
                icon: Icons.bar_chart_outlined,
                title: s.exportStatistics,
                subtitle: 'statistics.csv',
                onTap: _loading
                    ? null
                    : () => _run(
                        () => ExportService.exportStatsCsv(sessions)),
              ),
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.ios_share, size: 18),
      onTap: onTap,
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
