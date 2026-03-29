# MBGS — My Board Games Stats

A Flutter mobile app for managing a board game collection, tracking play sessions, and viewing statistics.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup](#setup)
3. [Running the App](#running-the-app)
4. [Debugging](#debugging)
5. [Project Structure](#project-structure)
6. [Architecture Overview](#architecture-overview)
7. [Database](#database)
8. [BGG API Integration](#bgg-api-integration)
9. [App Icon](#app-icon)
10. [Localization](#localization)
11. [Known Setup Issues](#known-setup-issues)

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | ^3.11.0 (tested on 3.41.2) | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| Dart SDK | Bundled with Flutter | |
| Android Studio | Any recent | For Android emulator / SDK |
| Android SDK | API 21+ | Min SDK is 21 (Android 5.0) |
| USB Debugging | Enabled on device | See [Known Setup Issues](#known-setup-issues) |

**Target test device:** Poco X6 — Android 15 / API 35 — device ID `2311DRK48G`

---

## Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd BoardGameAPP

# 2. Install dependencies
flutter pub get

# 3. Verify Flutter environment
flutter doctor
```

Everything should be green. The app uses no native plugins beyond `sqflite` and `url_launcher`, which have standard Android setup.

---

## Running the App

### On a physical device (recommended)

```bash
# List connected devices
flutter devices

# Run on Poco X6 (or whichever device ID appears)
flutter run -d 2311DRK48G

# Run in release mode (faster, no debug overlay)
flutter run -d 2311DRK48G --release
```

### On an emulator

```bash
# Start an emulator first from Android Studio, then:
flutter run
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Debugging

### VS Code

1. Open the project folder in VS Code.
2. Install the **Flutter** and **Dart** extensions.
3. Press `F5` (or Run → Start Debugging) — picks the connected device automatically.
4. Hot reload: `r` in the terminal, or `Ctrl+S` in VS Code.
5. Hot restart: `R` in the terminal.

### Android Studio

1. Open the project root in Android Studio.
2. Select a device from the device dropdown.
3. Click the green Run button or press `Shift+F10`.

### Useful debug commands

```bash
# See device logs (filter to app)
flutter logs

# Analyze code for issues
flutter analyze

# Run unit tests
flutter test

# Run a specific test file
flutter test test/services/ranking_service_test.dart
```

### Hot reload vs Hot restart

- **Hot reload** (`r`) — injects updated code, preserves app state. Use for UI tweaks.
- **Hot restart** (`R`) — restarts the app from scratch. Use after changing providers, DB schema, or routing logic.

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, MultiProvider setup
├── db/
│   └── database_helper.dart     # SQLite setup, migrations, all queries
├── l10n/
│   └── strings.dart             # English + Polish string keys
├── models/
│   ├── board_game.dart          # BoardGame data class
│   ├── game_session.dart        # GameSession data class
│   ├── player_result.dart       # PlayerResult data class
│   └── wishlist_item.dart       # WishlistItem data class
├── providers/
│   ├── game_provider.dart       # Board game collection state
│   ├── session_provider.dart    # Session state + saveSession()
│   ├── settings_provider.dart   # Theme, accent color, date format
│   ├── language_provider.dart   # Active language (en / pl)
│   └── wishlist_provider.dart   # Wishlist state
├── services/
│   ├── bgg_service.dart         # BoardGameGeek XML API v2 client
│   ├── ranking_service.dart     # Ranking / placement logic
│   └── stats_service.dart       # Stats aggregation logic
└── screens/
    ├── splash_screen.dart        # Animated splash (→ HomeScreen)
    ├── home_screen.dart          # Bottom nav shell (4 tabs)
    ├── settings/
    │   └── settings_screen.dart
    ├── catalog/
    │   ├── catalog_screen.dart   # Game collection list/grid
    │   ├── add_game_screen.dart  # Add / edit a game
    │   └── game_detail_screen.dart
    ├── session/
    │   ├── play_landing_screen.dart      # "Play new session" hub
    │   ├── game_night_picker_screen.dart # "What should we play?" picker
    │   ├── new_session_screen.dart       # Select game + players + expansions
    │   ├── random_starter_screen.dart    # Random first player picker
    │   ├── active_session_screen.dart    # Running timer screen
    │   ├── end_session_screen.dart       # Enter scores + ranks
    │   ├── add_results_screen.dart       # Retroactive result entry
    │   └── game_results_screen.dart      # Post-session results summary
    ├── history/
    │   ├── history_screen.dart           # All sessions, filterable
    │   └── session_detail_screen.dart    # Single session detail
    ├── statistics/
    │   ├── statistics_screen.dart        # Tab controller shell
    │   ├── tabs/
    │   │   ├── global_stats_tab.dart     # Totals, streaks, top players
    │   │   ├── games_stats_tab.dart      # Per-game stats list
    │   │   └── players_stats_tab.dart    # Per-player stats list + H2H picker
    │   ├── details/
    │   │   ├── game_detail_screen.dart   # Full stats for one game
    │   │   ├── player_detail_screen.dart # Full stats for one player
    │   │   └── head_to_head_screen.dart  # Head-to-head between two players
    │   └── shared/
    │       └── stat_widgets.dart         # _StatCard, _RecordRow, _SectionHeader, _medal
    └── wishlist/
        ├── wishlist_screen.dart
        └── add_wishlist_item_screen.dart
```

---

## Architecture Overview

### State management — Provider

Five providers registered at app root in `main.dart`:

| Provider | Responsibility |
|----------|---------------|
| `GameProvider` | Board game collection CRUD, BGG search |
| `SessionProvider` | Create/save sessions, player results |
| `SettingsProvider` | Theme (light/dark/system), accent color, date format |
| `LanguageProvider` | UI language (English / Polish) |
| `WishlistProvider` | Wishlist CRUD |

All providers read/write through `DatabaseHelper`.

### Navigation

Flat `Navigator.push` — no named routes. The bottom nav shell (`HomeScreen`) holds four tabs. Any drill-down (game detail, session flow, stats detail) is a pushed route.

### Session flow

```
PlayLandingScreen
  ├── NewSessionScreen (select game + players + expansions)
  │     └── RandomStarterScreen (optional)
  │           └── ActiveSessionScreen (timer)
  │                 └── EndSessionScreen (scores + ranks)
  │                       └── GameResultsScreen (summary)
  └── AddResultsScreen (retroactive, no timer)
```

### Teams

Sessions can be team-based (toggled in `NewSessionScreen`). Teams have custom names and a color-coded badge. Stored in DB — `teams` and `team_memberships` tables.

---

## Database

- Engine: **SQLite** via `sqflite`
- Managed by: `lib/db/database_helper.dart`
- Current schema version: **12**

### Tables

| Table | Description |
|-------|-------------|
| `board_games` | Game catalog (all BGG metadata fields + personal fields) |
| `game_sessions` | Session metadata (game, date, duration, notes, expansion_ids) |
| `player_results` | Per-player result per session (name, score, rank, team_id) |
| `wishlist_items` | Wishlist entries with BGG data |
| `teams` | Team records per session |
| `team_memberships` | Links players to teams |

### Schema evolution

Migrations are applied incrementally in `_onUpgrade()`. Each version bump adds columns or tables without dropping existing data. **Never decrease the version number** — it will cause a `DatabaseException`.

### Categories & Mechanics

Stored as JSON-encoded `TEXT` columns (e.g., `'["Strategy","Economic"]'`). Decoded via `_parseJsonList()` in `BoardGame.fromMap()`.

---

## BGG API Integration

The app uses the **BoardGameGeek XML API v2** (no auth required for public data).

### Flow

1. Search: `GET https://boardgamegeek.com/xmlapi2/search?query=<name>&type=boardgame`
   - Returns a list of game IDs.
2. Batch detail fetch: `GET https://boardgamegeek.com/xmlapi2/thing?id=1,2,3&stats=1`
   - Returns full metadata (playtime, ratings, complexity, categories, mechanics, minAge, etc.)
   - BGG may return HTTP 202 (queued) — the service retries automatically.

### Fields fetched

`name`, `description`, `imageUrl`, `thumbnailUrl`, `minPlayers`, `maxPlayers`,
`minPlaytime`, `maxPlaytime`, `bggRating`, `complexity`, `categories`, `mechanics`,
`yearPublished`, `minAge`, `bggId`

### File

`lib/services/bgg_service.dart` — `BggService` class with `searchGames()` and `getGameDetails()` methods.

---

## App Icon

Icon generation uses `flutter_launcher_icons`. Config is in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  image_path: "assets/icon.png"                          # legacy icon
  adaptive_icon_background: "#8B4513"                    # brown background
  adaptive_icon_foreground: "assets/icon_foreground.png" # padded foreground
```

`icon_foreground.png` is `icon.png` centered in a 1388×1388 canvas with ~232px transparent padding on each side — this keeps the logo within Android's adaptive icon 66% safe zone.

After changing the icon asset, regenerate and redeploy:

```bash
dart run flutter_launcher_icons
flutter run -d <device-id>
```

---

## Localization

Strings are managed manually in `lib/l10n/strings.dart`. Two locales are supported:

- `en` — English (default)
- `pl` — Polish

Usage in widgets:

```dart
final s = AppStrings.of(context);
Text(s.myGamesTitle)
```

To add a new string: add a getter to `AppStrings`, implement it in `_EnStrings` and `_PlStrings`.

---

## Known Setup Issues

### "System nie można odnaleźć" / flutter.bat exits with code 1

**Cause:** A stale `AutoRun` registry key (leftover from Miniconda uninstall) runs a missing `.bat` on every `cmd.exe` subprocess Flutter spawns.

**Fix:**
```powershell
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name 'Autorun' -Force
```

### INSTALL_FAILED_USER_RESTRICTED

**Cause:** MIUI security — "Install via USB" disabled in Developer Options.

**Fix:** Settings → Additional Settings → Developer options → Install via USB → ON

### Adaptive icon too small / too large

**Cause:** Using `icon.png` directly as `adaptive_icon_foreground` ignores Android's 66% safe zone.

**Fix:** Use the padded `icon_foreground.png` (see [App Icon](#app-icon) section).
