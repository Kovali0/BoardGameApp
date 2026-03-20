// ─── Abstract base ────────────────────────────────────────────────────────────

abstract class AppStrings {
  // Splash
  String get splashTitle;
  String get splashSubtitle;

  // Bottom nav
  String get navMyGames;
  String get navPlay;
  String get navHistory;
  String get navStatistics;
  String get navSettings;

  // Common
  String get cancel;
  String get delete;
  String get apply;
  String get filterAll;
  String get filterYear;
  String get filterMonth;

  // Catalog
  String get catalogTitle;
  String get catalogSearchHint;
  String get catalogEmpty;
  String get catalogNoResults;
  String get catalogClearFilters;
  String get catalogAddGame;
  String get catalogFilterTitle;
  String get catalogFilterClearAll;
  String get catalogFilterPlayers;
  String get catalogFilterPlaytime;
  String get catalogFilterPlaytime30;
  String get catalogFilterPlaytime60;
  String get catalogFilterPlaytime120;
  String get catalogFilterPlaytimeLong;
  String get catalogFilterMinRating;
  String get catalogFilterWeight;
  String get catalogFilterWeightLight;
  String get catalogFilterWeightMedium;
  String get catalogFilterWeightHeavy;
  String get catalogFilterStatus;
  String get catalogFilterNotPlayed;
  String catalogGamePlayers(int min, int max);

  // Add / Edit Game
  String get addGameTitle;
  String get editGameTitle;
  String get addGameBggSearchTitle;
  String get addGameBggSearchHint;
  String get addGameBggNotFound;
  String get addGameNameLabel;
  String get addGameDescriptionLabel;
  String get addGameMinPlayersLabel;
  String get addGameMaxPlayersLabel;
  String get addGameMinPlaytimeLabel;
  String get addGameMaxPlaytimeLabel;
  String get addGameBggRatingLabel;
  String get addGameBggWeightLabel;
  String get addGameMyNotesSection;
  String get addGameMyRatingLabel;
  String get addGameMyWeightLabel;
  String get addGameSetupHintsLabel;
  String get addGameSetupHintsHint;
  String get addGameButton;
  String get saveChangesButton;
  String get addGameBggError;
  String addGameBggFilled(String name);

  // Game Detail
  String get gameDetailBgg;
  String get gameDetailMine;
  String get gameDetailSetupHints;
  String get gameDetailPlayHistory;
  String get gameDetailNoSessions;
  String get gameDetailPlayNow;
  String get deleteGameTitle;
  String deleteGameContent(String name);

  // Play Landing
  String get playLandingTitle;
  String get playLandingStartNew;
  String get playLandingStartNewSub;
  String get playLandingAddResults;
  String get playLandingAddResultsSub;

  // New Session
  String get newSessionTitle;
  String get newSessionMyCollection;
  String get newSessionOtherGame;
  String get newSessionGame;
  String get newSessionGuestGameHint;
  String get newSessionNoGames;
  String get newSessionGameHint;
  String get newSessionPlayers;
  String get newSessionAddPlayer;
  String get newSessionPickStarter;
  String get newSessionMinPlayersError;
  String get newSessionEmptyGameError;
  String get newSessionNoGameError;
  String newSessionPlayerHint(int n);

  // Random Starter
  String get randomStarterQuestion;
  String get randomStarterSpin;
  String get randomStarterSpinning;
  String get randomStarterStartGame;
  String randomStarterWinner(String name);

  // Active Session
  String get activeAbandonTitle;
  String get activeAbandonContent;
  String get activeContinue;
  String get activeAbandon;
  String get activePause;
  String get activeResume;
  String get activeEndGame;
  String activeStarts(String name);

  // Shared Results (End Session + Add Results)
  String get resultsScoresHint;
  String get resultsScore;
  String get resultsTieTitle;
  String get resultsTieHintDrag;
  String get resultsTieHintTap;
  String get resultsTiebreakerLabel;
  String get resultsTiebreakerHint;
  String get resultsNotesLabel;
  String get resultsSaveButton;
  String get resultsAddPlayer;
  String get resultsDate;
  String get resultsDuration;
  String get resultsHours;
  String get resultsMinutes;
  String get resultsGameHint;
  String get resultsNoGames;
  String get resultsGameDropdownHint;
  String get resultsMyCollection;
  String get resultsOtherGame;
  String resultsTiedAt(int place);
  String resultsPlayerHint(int n);
  String ordinal(int n);

  // End Session
  String get endSessionTitle;
  String get endSessionStarted;

  // Add Results
  String get addResultsTitle;
  String get addResultsMinPlayersError;
  String get addResultsEmptyGameError;
  String get addResultsNoGameError;
  String get addResultsDurationError;

  // History
  String get historyTitle;
  String get historyEmpty;
  String get historyNoPeriod;
  String get historyFilterTitle;
  String historyWinner(String name);

  // Session Detail
  String get sessionDetailResults;
  String get sessionDetailStartedGame;
  String get sessionDetailNotes;
  String get deleteSessionTitle;
  String get deleteSessionContent;

  // Statistics
  String get statsTitle;
  String get statsGlobal;
  String get statsGamesTab;
  String get statsPlayersTab;
  String get statsNoSessions;
  String get statsPlayGames;
  String get statsCollection;
  String get statsPlayed;
  String get statsUnplayed;
  String get statsOverview;
  String get statsSessions;
  String get statsTimePlayed;
  String get statsTopGames;
  String get statsRecords;
  String get statsLongest;
  String get statsShortest;
  String get statsAvgDuration;
  String get statsHallOfFame;
  String get statsPlayedGames;
  String get statsNeverPlayed;
  String get statsNotPlayedYet;
  String get statsNoGames;
  String get statsAddGames;
  String get statsAvgPlayers;
  String get statsLastPlayed;
  String get statsBestPlayer;
  String get statsHighestScore;
  String get statsAvgScore;
  String get statsLowestScore;
  String get statsNoPlayers;
  String get statsPlayForPlayerStats;
  String get statsWins;
  String get statsWinRate;
  String get statsSecondPlaces;
  String get statsThirdPlaces;
  String get statsGameBreakdown;
  String get statsMostPlayed;
  String get statsTotalTime;
  String get statsBestScore;
  String get statsGames;
  String get statsFilterTitle;

  // Settings
  String get settingsTitle;
  String get settingsAppearance;
  String get settingsTheme;
  String get settingsThemeSystem;
  String get settingsThemeLight;
  String get settingsThemeDark;
  String get settingsAccentColor;
  String get settingsGeneral;
  String get settingsLanguage;
  String get settingsDateFormat;
  String get settingsAbout;
  String get settingsVersion;
  String get settingsBggCredit;
  String get settingsBuiltWith;
}

// ─── English ──────────────────────────────────────────────────────────────────

class EnStrings extends AppStrings {
  // Splash
  @override String get splashTitle => 'Board Game\nManager';
  @override String get splashSubtitle => 'Your collection, your stats';

  // Bottom nav
  @override String get navMyGames => 'My Games';
  @override String get navPlay => 'Play';
  @override String get navHistory => 'History';
  @override String get navStatistics => 'Statistics';
  @override String get navSettings => 'Settings';

  // Common
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get apply => 'Apply';
  @override String get filterAll => 'All';
  @override String get filterYear => 'Year';
  @override String get filterMonth => 'Month';

  // Catalog
  @override String get catalogTitle => 'My Games Collection';
  @override String get catalogSearchHint => 'Search game...';
  @override String get catalogEmpty => 'No games yet. Add your first game!';
  @override String get catalogNoResults => 'No games match your search or filters.';
  @override String get catalogClearFilters => 'Clear search & filters';
  @override String get catalogAddGame => 'Add Game';
  @override String get catalogFilterTitle => 'Filter games';
  @override String get catalogFilterClearAll => 'Clear all';
  @override String get catalogFilterPlayers => 'Players';
  @override String get catalogFilterPlaytime => 'Playtime';
  @override String get catalogFilterPlaytime30 => '≤ 30 min';
  @override String get catalogFilterPlaytime60 => '≤ 60 min';
  @override String get catalogFilterPlaytime120 => '≤ 120 min';
  @override String get catalogFilterPlaytimeLong => 'Long (120+)';
  @override String get catalogFilterMinRating => 'Min Rating';
  @override String get catalogFilterWeight => 'Weight';
  @override String get catalogFilterWeightLight => 'Light (≤2)';
  @override String get catalogFilterWeightMedium => 'Medium';
  @override String get catalogFilterWeightHeavy => 'Heavy (3.5+)';
  @override String get catalogFilterStatus => 'Status';
  @override String get catalogFilterNotPlayed => 'Not played yet';
  @override String catalogGamePlayers(int min, int max) => '$min–$max players';

  // Add / Edit Game
  @override String get addGameTitle => 'Add Game';
  @override String get editGameTitle => 'Edit Game';
  @override String get addGameBggSearchTitle => 'Search game database';
  @override String get addGameBggSearchHint => 'Search by name (English or native language)...';
  @override String get addGameBggNotFound => 'Not found in database — fill the details manually below.';
  @override String get addGameNameLabel => 'Game Name *';
  @override String get addGameDescriptionLabel => 'Description';
  @override String get addGameMinPlayersLabel => 'Min Players';
  @override String get addGameMaxPlayersLabel => 'Max Players';
  @override String get addGameMinPlaytimeLabel => 'Min Playtime (min)';
  @override String get addGameMaxPlaytimeLabel => 'Max Playtime (min)';
  @override String get addGameBggRatingLabel => 'BGG Rating (1–10)';
  @override String get addGameBggWeightLabel => 'BGG Weight (1–5)';
  @override String get addGameMyNotesSection => 'My Notes';
  @override String get addGameMyRatingLabel => 'My Rating (1–10)';
  @override String get addGameMyWeightLabel => 'My Weight (1–5)';
  @override String get addGameSetupHintsLabel => 'Setup Hints';
  @override String get addGameSetupHintsHint => 'e.g. 1. Place board in center\n2. Deal 5 cards each...';
  @override String get addGameButton => 'Add Game';
  @override String get saveChangesButton => 'Save Changes';
  @override String get addGameBggError => 'Could not fill game details';
  @override String addGameBggFilled(String name) => 'Filled from BGG: $name';

  // Game Detail
  @override String get gameDetailBgg => 'BGG';
  @override String get gameDetailMine => 'Mine';
  @override String get gameDetailSetupHints => 'Setup Hints';
  @override String get gameDetailPlayHistory => 'Play History';
  @override String get gameDetailNoSessions => 'No sessions yet for this game.';
  @override String get gameDetailPlayNow => 'Play Now';
  @override String get deleteGameTitle => 'Delete Game?';
  @override String deleteGameContent(String name) => 'Are you sure you want to delete "$name"?';

  // Play Landing
  @override String get playLandingTitle => 'Play new session';
  @override String get playLandingStartNew => 'Start a new game';
  @override String get playLandingStartNewSub => 'Track time live with the timer';
  @override String get playLandingAddResults => 'Add results of a game';
  @override String get playLandingAddResultsSub => 'Already played? Log it manually';

  // New Session
  @override String get newSessionTitle => 'New Game';
  @override String get newSessionMyCollection => 'My Collection';
  @override String get newSessionOtherGame => 'Other Game';
  @override String get newSessionGame => 'Game';
  @override String get newSessionGuestGameHint => 'Game name...';
  @override String get newSessionNoGames => 'No games in catalog. Add a game first!';
  @override String get newSessionGameHint => 'Choose a game...';
  @override String get newSessionPlayers => 'Players';
  @override String get newSessionAddPlayer => 'Add Player';
  @override String get newSessionPickStarter => 'Pick Who Starts!';
  @override String get newSessionMinPlayersError => 'Add at least 2 players';
  @override String get newSessionEmptyGameError => 'Enter a game name';
  @override String get newSessionNoGameError => 'Please select a game first';
  @override String newSessionPlayerHint(int n) => 'Player $n name';

  // Random Starter
  @override String get randomStarterQuestion => 'Who starts the game?';
  @override String get randomStarterSpin => 'Spin!';
  @override String get randomStarterSpinning => 'Spinning...';
  @override String get randomStarterStartGame => 'Start Game!';
  @override String randomStarterWinner(String name) => '$name goes first!';

  // Active Session
  @override String get activeAbandonTitle => 'Abandon Game?';
  @override String get activeAbandonContent => 'The current session will be lost.';
  @override String get activeContinue => 'Continue';
  @override String get activeAbandon => 'Abandon';
  @override String get activePause => 'Pause';
  @override String get activeResume => 'Resume';
  @override String get activeEndGame => 'End Game';
  @override String activeStarts(String name) => '$name starts';

  // Shared Results
  @override String get resultsScoresHint => 'Enter scores — ranks update automatically.';
  @override String get resultsScore => 'Score';
  @override String get resultsTieTitle => 'Resolve Ties';
  @override String get resultsTieHintDrag => 'Drag to set the final order within each tied group.';
  @override String get resultsTieHintTap => 'Tap arrows to set the final order within each tied group.';
  @override String get resultsTiebreakerLabel => 'Tiebreaker reason (optional)';
  @override String get resultsTiebreakerHint => 'e.g. "A and B tied — B won by card count"';
  @override String get resultsNotesLabel => 'Notes (optional)';
  @override String get resultsSaveButton => 'Save Session';
  @override String get resultsAddPlayer => 'Add';
  @override String get resultsDate => 'Date';
  @override String get resultsDuration => 'Duration';
  @override String get resultsHours => 'h';
  @override String get resultsMinutes => 'min';
  @override String get resultsGameHint => 'Game name...';
  @override String get resultsNoGames => 'No games in catalog. Add a game first!';
  @override String get resultsGameDropdownHint => 'Choose a game...';
  @override String get resultsMyCollection => 'My Collection';
  @override String get resultsOtherGame => 'Other Game';
  @override String resultsTiedAt(int place) {
    final ordinal = place == 1 ? '1st' : place == 2 ? '2nd' : place == 3 ? '3rd' : '${place}th';
    return 'Tied at $ordinal place — set final order:';
  }
  @override String resultsPlayerHint(int n) => 'Player $n';
  @override String ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  // End Session
  @override String get endSessionTitle => 'Game Over!';
  @override String get endSessionStarted => 'started';

  // Add Results
  @override String get addResultsTitle => 'Add Results';
  @override String get addResultsMinPlayersError => 'Add at least 2 players';
  @override String get addResultsEmptyGameError => 'Enter a game name';
  @override String get addResultsNoGameError => 'Please select a game';
  @override String get addResultsDurationError => 'Duration must be at least 1 minute';

  // History
  @override String get historyTitle => 'Sessions history';
  @override String get historyEmpty => 'No sessions yet. Play a game!';
  @override String get historyNoPeriod => 'No sessions in this period.';
  @override String get historyFilterTitle => 'Filter sessions';
  @override String historyWinner(String name) => 'Winner: $name';

  // Session Detail
  @override String get sessionDetailResults => 'Results';
  @override String get sessionDetailStartedGame => 'started the game';
  @override String get sessionDetailNotes => 'Notes';
  @override String get deleteSessionTitle => 'Delete Session?';
  @override String get deleteSessionContent => 'This session record will be permanently deleted.';

  // Statistics
  @override String get statsTitle => 'Useless statistics';
  @override String get statsGlobal => 'Global';
  @override String get statsGamesTab => 'Games';
  @override String get statsPlayersTab => 'Players';
  @override String get statsNoSessions => 'No sessions yet';
  @override String get statsPlayGames => 'Play some games to see your stats!';
  @override String get statsCollection => 'COLLECTION';
  @override String get statsPlayed => 'Played';
  @override String get statsUnplayed => 'Unplayed';
  @override String get statsOverview => 'OVERVIEW';
  @override String get statsSessions => 'Sessions';
  @override String get statsTimePlayed => 'Time played';
  @override String get statsTopGames => 'Top Games';
  @override String get statsRecords => 'RECORDS';
  @override String get statsLongest => 'Longest session';
  @override String get statsShortest => 'Shortest session';
  @override String get statsAvgDuration => 'Average duration';
  @override String get statsHallOfFame => 'PLAYER HALL OF FAME';
  @override String get statsPlayedGames => 'PLAYED GAMES';
  @override String get statsNeverPlayed => 'NEVER PLAYED';
  @override String get statsNotPlayedYet => 'Not played yet';
  @override String get statsNoGames => 'No games yet';
  @override String get statsAddGames => 'Add games to your collection!';
  @override String get statsAvgPlayers => 'Avg players';
  @override String get statsLastPlayed => 'Last played';
  @override String get statsBestPlayer => 'Best player';
  @override String get statsHighestScore => 'Highest score';
  @override String get statsAvgScore => 'Avg score';
  @override String get statsLowestScore => 'Lowest score';
  @override String get statsNoPlayers => 'No players yet';
  @override String get statsPlayForPlayerStats => 'Play some games to see player stats!';
  @override String get statsWins => 'Wins';
  @override String get statsWinRate => 'Win rate';
  @override String get statsSecondPlaces => '2nd places';
  @override String get statsThirdPlaces => '3rd places';
  @override String get statsGameBreakdown => 'GAME BREAKDOWN';
  @override String get statsMostPlayed => 'Most played';
  @override String get statsTotalTime => 'Total time';
  @override String get statsBestScore => 'Best score';
  @override String get statsGames => 'Games';
  @override String get statsFilterTitle => 'Filter sessions';

  // Settings
  @override String get settingsTitle => 'Settings';
  @override String get settingsAppearance => 'APPEARANCE';
  @override String get settingsTheme => 'Theme';
  @override String get settingsThemeSystem => 'System';
  @override String get settingsThemeLight => 'Light';
  @override String get settingsThemeDark => 'Dark';
  @override String get settingsAccentColor => 'Accent color';
  @override String get settingsGeneral => 'GENERAL';
  @override String get settingsLanguage => 'Language';
  @override String get settingsDateFormat => 'Date format';
  @override String get settingsAbout => 'ABOUT';
  @override String get settingsVersion => 'Version 1.0.0';
  @override String get settingsBggCredit => 'Board game data powered by BoardGameGeek';
  @override String get settingsBuiltWith => 'Built with Flutter ❤️';
}

// ─── Polish ───────────────────────────────────────────────────────────────────

class PlStrings extends AppStrings {
  // Splash
  @override String get splashTitle => 'Menedżer\nGier Planszowych';
  @override String get splashSubtitle => 'Twoja kolekcja, Twoje statystyki';

  // Bottom nav
  @override String get navMyGames => 'Moje gry';
  @override String get navPlay => 'Graj';
  @override String get navHistory => 'Historia';
  @override String get navStatistics => 'Statystyki';
  @override String get navSettings => 'Ustawienia';

  // Common
  @override String get cancel => 'Anuluj';
  @override String get delete => 'Usuń';
  @override String get apply => 'Zastosuj';
  @override String get filterAll => 'Wszystkie';
  @override String get filterYear => 'Rok';
  @override String get filterMonth => 'Miesiąc';

  // Catalog
  @override String get catalogTitle => 'Moja kolekcja gier';
  @override String get catalogSearchHint => 'Szukaj gry...';
  @override String get catalogEmpty => 'Brak gier. Dodaj pierwszą grę!';
  @override String get catalogNoResults => 'Żadne gry nie pasują do wyszukiwania lub filtrów.';
  @override String get catalogClearFilters => 'Wyczyść wyszukiwanie i filtry';
  @override String get catalogAddGame => 'Dodaj grę';
  @override String get catalogFilterTitle => 'Filtruj gry';
  @override String get catalogFilterClearAll => 'Wyczyść wszystko';
  @override String get catalogFilterPlayers => 'Gracze';
  @override String get catalogFilterPlaytime => 'Czas gry';
  @override String get catalogFilterPlaytime30 => '≤ 30 min';
  @override String get catalogFilterPlaytime60 => '≤ 60 min';
  @override String get catalogFilterPlaytime120 => '≤ 120 min';
  @override String get catalogFilterPlaytimeLong => 'Długa (120+)';
  @override String get catalogFilterMinRating => 'Min ocena';
  @override String get catalogFilterWeight => 'Złożoność';
  @override String get catalogFilterWeightLight => 'Lekka (≤2)';
  @override String get catalogFilterWeightMedium => 'Średnia';
  @override String get catalogFilterWeightHeavy => 'Ciężka (3.5+)';
  @override String get catalogFilterStatus => 'Status';
  @override String get catalogFilterNotPlayed => 'Jeszcze nie grana';
  @override String catalogGamePlayers(int min, int max) => '$min–$max graczy';

  // Add / Edit Game
  @override String get addGameTitle => 'Dodaj grę';
  @override String get editGameTitle => 'Edytuj grę';
  @override String get addGameBggSearchTitle => 'Szukaj w bazie gier';
  @override String get addGameBggSearchHint => 'Szukaj po nazwie (angielskiej lub oryginalnej)...';
  @override String get addGameBggNotFound => 'Nie znaleziono w bazie — wypełnij szczegóły ręcznie.';
  @override String get addGameNameLabel => 'Nazwa gry *';
  @override String get addGameDescriptionLabel => 'Opis';
  @override String get addGameMinPlayersLabel => 'Min graczy';
  @override String get addGameMaxPlayersLabel => 'Max graczy';
  @override String get addGameMinPlaytimeLabel => 'Min czas gry (min)';
  @override String get addGameMaxPlaytimeLabel => 'Max czas gry (min)';
  @override String get addGameBggRatingLabel => 'Ocena BGG (1–10)';
  @override String get addGameBggWeightLabel => 'Złożoność BGG (1–5)';
  @override String get addGameMyNotesSection => 'Moje notatki';
  @override String get addGameMyRatingLabel => 'Moja ocena (1–10)';
  @override String get addGameMyWeightLabel => 'Moja złożoność (1–5)';
  @override String get addGameSetupHintsLabel => 'Wskazówki do ustawienia';
  @override String get addGameSetupHintsHint => 'np. 1. Połóż planszę na środku\n2. Rozdaj 5 kart każdemu...';
  @override String get addGameButton => 'Dodaj grę';
  @override String get saveChangesButton => 'Zapisz zmiany';
  @override String get addGameBggError => 'Nie udało się pobrać danych gry';
  @override String addGameBggFilled(String name) => 'Wypełniono z BGG: $name';

  // Game Detail
  @override String get gameDetailBgg => 'BGG';
  @override String get gameDetailMine => 'Moje';
  @override String get gameDetailSetupHints => 'Wskazówki do ustawienia';
  @override String get gameDetailPlayHistory => 'Historia gier';
  @override String get gameDetailNoSessions => 'Brak sesji dla tej gry.';
  @override String get gameDetailPlayNow => 'Zagraj teraz';
  @override String get deleteGameTitle => 'Usunąć grę?';
  @override String deleteGameContent(String name) => 'Na pewno chcesz usunąć "$name"?';

  // Play Landing
  @override String get playLandingTitle => 'Nowa sesja';
  @override String get playLandingStartNew => 'Rozpocznij nową grę';
  @override String get playLandingStartNewSub => 'Śledź czas na żywo z timerem';
  @override String get playLandingAddResults => 'Dodaj wyniki gry';
  @override String get playLandingAddResultsSub => 'Już grałeś? Zapisz ręcznie';

  // New Session
  @override String get newSessionTitle => 'Nowa gra';
  @override String get newSessionMyCollection => 'Moja kolekcja';
  @override String get newSessionOtherGame => 'Inna gra';
  @override String get newSessionGame => 'Gra';
  @override String get newSessionGuestGameHint => 'Nazwa gry...';
  @override String get newSessionNoGames => 'Brak gier w katalogu. Najpierw dodaj grę!';
  @override String get newSessionGameHint => 'Wybierz grę...';
  @override String get newSessionPlayers => 'Gracze';
  @override String get newSessionAddPlayer => 'Dodaj gracza';
  @override String get newSessionPickStarter => 'Wybierz kto zaczyna!';
  @override String get newSessionMinPlayersError => 'Dodaj co najmniej 2 graczy';
  @override String get newSessionEmptyGameError => 'Podaj nazwę gry';
  @override String get newSessionNoGameError => 'Wybierz grę';
  @override String newSessionPlayerHint(int n) => 'Imię gracza $n';

  // Random Starter
  @override String get randomStarterQuestion => 'Kto zaczyna grę?';
  @override String get randomStarterSpin => 'Losuj!';
  @override String get randomStarterSpinning => 'Losuję...';
  @override String get randomStarterStartGame => 'Zacznij grę!';
  @override String randomStarterWinner(String name) => '$name zaczyna!';

  // Active Session
  @override String get activeAbandonTitle => 'Porzucić grę?';
  @override String get activeAbandonContent => 'Aktualna sesja zostanie utracona.';
  @override String get activeContinue => 'Kontynuuj';
  @override String get activeAbandon => 'Porzuć';
  @override String get activePause => 'Pauza';
  @override String get activeResume => 'Wznów';
  @override String get activeEndGame => 'Zakończ grę';
  @override String activeStarts(String name) => '$name zaczyna';

  // Shared Results
  @override String get resultsScoresHint => 'Wpisz wyniki — rangi aktualizują się automatycznie.';
  @override String get resultsScore => 'Wynik';
  @override String get resultsTieTitle => 'Rozwiąż remisy';
  @override String get resultsTieHintDrag => 'Przeciągnij, aby ustawić kolejność w grupie remisów.';
  @override String get resultsTieHintTap => 'Naciśnij strzałki, aby ustawić kolejność w grupie remisów.';
  @override String get resultsTiebreakerLabel => 'Powód rozstrzygnięcia (opcjonalnie)';
  @override String get resultsTiebreakerHint => 'np. "A i B zremisowali — B wygrało liczbą kart"';
  @override String get resultsNotesLabel => 'Notatki (opcjonalnie)';
  @override String get resultsSaveButton => 'Zapisz sesję';
  @override String get resultsAddPlayer => 'Dodaj';
  @override String get resultsDate => 'Data';
  @override String get resultsDuration => 'Czas';
  @override String get resultsHours => 'g';
  @override String get resultsMinutes => 'min';
  @override String get resultsGameHint => 'Nazwa gry...';
  @override String get resultsNoGames => 'Brak gier w katalogu. Najpierw dodaj grę!';
  @override String get resultsGameDropdownHint => 'Wybierz grę...';
  @override String get resultsMyCollection => 'Moja kolekcja';
  @override String get resultsOtherGame => 'Inna gra';
  @override String resultsTiedAt(int place) => 'Remis na $place. miejscu — ustaw kolejność:';
  @override String resultsPlayerHint(int n) => 'Gracz $n';
  @override String ordinal(int n) => '$n.';

  // End Session
  @override String get endSessionTitle => 'Koniec gry!';
  @override String get endSessionStarted => 'zaczął';

  // Add Results
  @override String get addResultsTitle => 'Dodaj wyniki';
  @override String get addResultsMinPlayersError => 'Dodaj co najmniej 2 graczy';
  @override String get addResultsEmptyGameError => 'Podaj nazwę gry';
  @override String get addResultsNoGameError => 'Wybierz grę';
  @override String get addResultsDurationError => 'Czas musi wynosić co najmniej 1 minutę';

  // History
  @override String get historyTitle => 'Historia sesji';
  @override String get historyEmpty => 'Brak sesji. Zagraj w grę!';
  @override String get historyNoPeriod => 'Brak sesji w tym okresie.';
  @override String get historyFilterTitle => 'Filtruj sesje';
  @override String historyWinner(String name) => 'Zwycięzca: $name';

  // Session Detail
  @override String get sessionDetailResults => 'Wyniki';
  @override String get sessionDetailStartedGame => 'zaczął grę';
  @override String get sessionDetailNotes => 'Notatki';
  @override String get deleteSessionTitle => 'Usunąć sesję?';
  @override String get deleteSessionContent => 'Ta sesja zostanie trwale usunięta.';

  // Statistics
  @override String get statsTitle => 'Bezużyteczne statystyki';
  @override String get statsGlobal => 'Globalne';
  @override String get statsGamesTab => 'Gry';
  @override String get statsPlayersTab => 'Gracze';
  @override String get statsNoSessions => 'Brak sesji';
  @override String get statsPlayGames => 'Zagraj w gry, aby zobaczyć statystyki!';
  @override String get statsCollection => 'KOLEKCJA';
  @override String get statsPlayed => 'Grane';
  @override String get statsUnplayed => 'Niegrane';
  @override String get statsOverview => 'PRZEGLĄD';
  @override String get statsSessions => 'Sesje';
  @override String get statsTimePlayed => 'Czas gry';
  @override String get statsTopGames => 'Najlepsze gry';
  @override String get statsRecords => 'REKORDY';
  @override String get statsLongest => 'Najdłuższa sesja';
  @override String get statsShortest => 'Najkrótsza sesja';
  @override String get statsAvgDuration => 'Średni czas';
  @override String get statsHallOfFame => 'HALL OF FAME GRACZY';
  @override String get statsPlayedGames => 'GRANE GRY';
  @override String get statsNeverPlayed => 'NIGDY NIE GRANE';
  @override String get statsNotPlayedYet => 'Jeszcze nie grana';
  @override String get statsNoGames => 'Brak gier';
  @override String get statsAddGames => 'Dodaj gry do kolekcji!';
  @override String get statsAvgPlayers => 'Śr. graczy';
  @override String get statsLastPlayed => 'Ostatnio grana';
  @override String get statsBestPlayer => 'Najlepszy gracz';
  @override String get statsHighestScore => 'Najwyższy wynik';
  @override String get statsAvgScore => 'Śr. wynik';
  @override String get statsLowestScore => 'Najniższy wynik';
  @override String get statsNoPlayers => 'Brak graczy';
  @override String get statsPlayForPlayerStats => 'Zagraj w gry, aby zobaczyć statystyki graczy!';
  @override String get statsWins => 'Wygrane';
  @override String get statsWinRate => 'Wygrane %';
  @override String get statsSecondPlaces => '2. miejsca';
  @override String get statsThirdPlaces => '3. miejsca';
  @override String get statsGameBreakdown => 'PODZIAŁ GIER';
  @override String get statsMostPlayed => 'Najczęściej grana';
  @override String get statsTotalTime => 'Łączny czas';
  @override String get statsBestScore => 'Najlepszy wynik';
  @override String get statsGames => 'Gry';
  @override String get statsFilterTitle => 'Filtruj sesje';

  // Settings
  @override String get settingsTitle => 'Ustawienia';
  @override String get settingsAppearance => 'WYGLĄD';
  @override String get settingsTheme => 'Motyw';
  @override String get settingsThemeSystem => 'Systemowy';
  @override String get settingsThemeLight => 'Jasny';
  @override String get settingsThemeDark => 'Ciemny';
  @override String get settingsAccentColor => 'Kolor akcentu';
  @override String get settingsGeneral => 'OGÓLNE';
  @override String get settingsLanguage => 'Język';
  @override String get settingsDateFormat => 'Format daty';
  @override String get settingsAbout => 'O APLIKACJI';
  @override String get settingsVersion => 'Wersja 1.0.0';
  @override String get settingsBggCredit => 'Dane gier dostarczone przez BoardGameGeek';
  @override String get settingsBuiltWith => 'Stworzone z Flutter ❤️';
}
