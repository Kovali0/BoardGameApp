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
  String get filterGame;
  String get filterPlayer;

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
  String get catalogTabCollection;
  String get catalogTabWishlist;
  String get catalogSortAZ;
  String get catalogSortZA;
  String get catalogSortRecentlyAdded;
  String get catalogSortMyRating;
  String get historySortNewest;
  String get historySortOldest;
  String get historySortByGame;

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
  String get rematch;
  String get gameResultsTitle;
  String get gameResultsClose;
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
  String get sessionLocationLabel;
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
  String get sessionDetailTiebreaker;
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
  String get statsPresetAllTime;
  String get statsPresetLast30;
  String get statsPresetLast3m;
  String get statsPresetLast6m;
  String get statsPresetThisYear;
  String get statsPresetCustom;
  String get statsFilterFrom;
  String get statsFilterTo;
  String get statsHeadToHead;
  String get statsSelectPlayer;
  String get statsViewRivalry;
  String get statsTogetherSessions;
  String get statsDraws;
  String get statsNeverPlayedTogether;

  // Teams
  String get teamGame;
  String get teamGameSub;
  String get teamCount;
  String teamNameHint(int n);
  String get teamAssign;
  String get statsBestTeams;
  String get statsBestPartner;
  String get statsWorstPartner;
  String get statsPartnerSessions;
  String get statsPartnerWins;
  String get statsHeatmap;
  String get statsHeatmapLess;
  String get statsHeatmapMore;

  // Wishlist
  String get navWishlist;
  String get wishlistTitle;
  String get wishlistEmpty;
  String get wishlistAddItem;
  String get wishlistAddTitle;
  String get wishlistEditTitle;
  String get wishlistNameLabel;
  String get wishlistNoteLabel;
  String get wishlistNoteHint;
  String get wishlistPriority;
  String get wishlistPriorityLow;
  String get wishlistPriorityMedium;
  String get wishlistPriorityHigh;
  String get wishlistMoveToCollection;
  String get wishlistMoveConfirmTitle;
  String wishlistMoveConfirmContent(String name);
  String get wishlistDeleteTitle;
  String wishlistDeleteContent(String name);
  String get wishlistBggFilled;
  String get wishlistSave;
  String get wishlistPriceLabel;
  String get wishlistSearchOnline;
  String get wishlistSearchSuffix; // appended to game name when searching
  String get wishlistSortPriority;
  String get wishlistSortPriceLow;
  String get wishlistSortPriceHigh;
  String get wishlistNoResults;
  String get wishlistClearFilters;
  String get wishlistFilterByPriority;

  // Expansions
  String get expansionsTitle;
  String get expansionBaseGame;
  String get expansionOwned;
  String get expansionAdd;
  String get expansionAdded;
  String get expansionNone;
  String get expansionNoBgg;
  String get expansionLinkToBgg;
  String get filterGameType;
  String get filterGameTypeBase;
  String get filterGameTypeExpansions;
  String expansionOf(String name);
  String get sessionExpansionsSection;
  String get historyFilterWithExpansions;
  String get statsMostUsedExpansion;
  String get statsSessionsWithExpansions;

  // Game Night Picker
  String get pickerTitle;
  String get pickerLandingTitle;
  String get pickerLandingSub;
  String get pickerPlayers;
  String get pickerTime;
  String get pickerNoLimit;
  String get pickerComplexity;
  String get pickerComplexityAny;
  String get pickerComplexityLight;
  String get pickerComplexityMedium;
  String get pickerComplexityHeavy;
  String get pickerNotPlayedYet;
  String get pickerFind;
  String get pickerNoResults;
  String get pickerRandomPick;
  String get pickerPlay;
  String pickerResults(int n);
  String get pickerPickGame;
  String get pickerCategories;
  String get pickerMechanics;
  String get pickerFamilyFriendly;
  String get pickerYearEra;
  String get pickerYearClassic;
  String get pickerYearModern;
  String get pickerYearRecent;

  // Collection value
  String get catalogCollectionValue;
  String get catalogTotalSpent;
  String get catalogCurrentValue;
  String get catalogValueGain;
  String catalogGamesTracked(int n);

  // Purchase info (add/edit game)
  String get addGamePurchaseSection;
  String get addGameBoughtPriceLabel;
  String get addGameCurrentPriceLabel;
  String get addGameAcquiredAtLabel;
  String get addGameAcquiredAtNone;
  String get addGameSearchCurrentPrice;
  String get addGameSealedLabel;

  // Game detail — price
  String get gameDetailBoughtPrice;
  String get gameDetailCurrentPrice;
  String get gameDetailAcquiredAt;
  String get gameDetailWithExpansions;
  String get gameDetailCostPerPlay;

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
  String get settingsDefaultPlayers;
  String get settingsDefaultPlayersHint;
  String get settingsDefaultPlayersAdd;
  String get settingsDefaultPlayersEmpty;
  String get settingsTimerFeedback;
  String get settingsTimerFeedbackSub;
  String get settingsQuickAdd;
  String get settingsAbout;
  String get settingsVersion;
  String get settingsBggCredit;
  String get settingsBuiltWith;

  // Import
  String get settingsImport;
  String get importFullJson;
  String get importFullJsonSub;
  String get importSessions;
  String get importSessionsSub;
  String get importCollection;
  String get importCollectionSub;
  String get importWishlist;
  String get importWishlistSub;
  String get importReading;
  String importJsonResult(int games, int sessions, int wishlist);
  String importCsvResult(int added, int skipped);
  String get importError;
  String get importNoFile;

  // Export
  String get settingsExport;
  String get exportFullJson;
  String get exportFullJsonSub;
  String get exportFullZip;
  String get exportFullZipSub;
  String get exportIndividual;
  String get exportSessions;
  String get exportCollection;
  String get exportWishlist;
  String get exportStatistics;
  String get exportPreparing;
  String get exportDone;
  String get settingsCurrency;
  String get settingsPriceSearch;

  // BGG Account
  String get settingsBgg;
  String get settingsBggUsername;
  String get settingsBggUsernameHint;
  String get settingsBggSync;
  String get settingsBggSyncing;
  String settingsBggSyncResult(int added, int skipped);
  String get settingsBggSyncError;
  String get settingsBggUserNotFound;
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
  @override String get filterGame => 'Game';
  @override String get filterPlayer => 'Player';

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
  @override String get catalogTabCollection => 'Collection';
  @override String get catalogTabWishlist => 'Wishlist';
  @override String get catalogSortAZ => 'A → Z';
  @override String get catalogSortZA => 'Z → A';
  @override String get catalogSortRecentlyAdded => 'Recently added';
  @override String get catalogSortMyRating => 'My rating';
  @override String get historySortNewest => 'Newest first';
  @override String get historySortOldest => 'Oldest first';
  @override String get historySortByGame => 'By game name';

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
  @override String get rematch => 'Rematch';
  @override String get gameResultsTitle => 'Game Results';
  @override String get gameResultsClose => 'Close';
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
  @override String get sessionLocationLabel => 'Location (optional)';
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
  @override String get sessionDetailTiebreaker => 'Tiebreaker';
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
  @override String get statsPresetAllTime => 'All time';
  @override String get statsPresetLast30 => 'Last 30 days';
  @override String get statsPresetLast3m => 'Last 3 months';
  @override String get statsPresetLast6m => 'Last 6 months';
  @override String get statsPresetThisYear => 'This year';
  @override String get statsPresetCustom => 'Custom';
  @override String get statsFilterFrom => 'From';
  @override String get statsFilterTo => 'To';
  @override String get statsHeadToHead => 'Head-to-head';
  @override String get statsSelectPlayer => 'Select player...';
  @override String get statsViewRivalry => 'Compare';
  @override String get statsTogetherSessions => 'Together';
  @override String get statsDraws => 'Draws';
  @override String get statsNeverPlayedTogether => 'These players have never played together.';

  // Teams
  @override String get teamGame => 'Team game';
  @override String get teamGameSub => 'Players compete in teams';
  @override String get teamCount => 'Number of teams';
  @override String teamNameHint(int n) => 'Team $n';
  @override String get teamAssign => 'Team';
  @override String get statsBestTeams => 'BEST TEAMS';
  @override String get statsBestPartner => 'Best team partner';
  @override String get statsWorstPartner => 'Worst team partner';
  @override String get statsPartnerSessions => 'Sessions together';
  @override String get statsPartnerWins => 'Wins together';
  @override String get statsHeatmap => 'ACTIVITY';
  @override String get statsHeatmapLess => 'Less';
  @override String get statsHeatmapMore => 'More';

  // Wishlist
  @override String get navWishlist => 'Wishlist';
  @override String get wishlistTitle => 'Wishlist';
  @override String get wishlistEmpty => 'No games on your wishlist yet.';
  @override String get wishlistAddItem => 'Add to Wishlist';
  @override String get wishlistAddTitle => 'Add to Wishlist';
  @override String get wishlistEditTitle => 'Edit Wishlist Item';
  @override String get wishlistNameLabel => 'Game Name *';
  @override String get wishlistNoteLabel => 'Note (optional)';
  @override String get wishlistNoteHint => 'e.g. "Wait for sale", "Ask for birthday"...';
  @override String get wishlistPriority => 'Priority';
  @override String get wishlistPriorityLow => 'Low';
  @override String get wishlistPriorityMedium => 'Medium';
  @override String get wishlistPriorityHigh => 'High';
  @override String get wishlistMoveToCollection => 'Move to Collection';
  @override String get wishlistMoveConfirmTitle => 'Move to Collection?';
  @override String wishlistMoveConfirmContent(String name) =>
      '"$name" will be added to your collection and removed from the wishlist.';
  @override String get wishlistDeleteTitle => 'Remove from Wishlist?';
  @override String wishlistDeleteContent(String name) =>
      'Remove "$name" from your wishlist?';
  @override String get wishlistBggFilled => 'Details filled from BGG';
  @override String get wishlistSave => 'Save';
  @override String get wishlistPriceLabel => 'Target price (optional)';
  @override String get wishlistSearchOnline => 'Search online';
  @override String get wishlistSearchSuffix => 'board game';
  @override String get wishlistSortPriority => 'Priority (high first)';
  @override String get wishlistSortPriceLow => 'Price: low → high';
  @override String get wishlistSortPriceHigh => 'Price: high → low';
  @override String get wishlistNoResults => 'No items match your filters.';
  @override String get wishlistClearFilters => 'Clear filters';
  @override String get wishlistFilterByPriority => 'Filter by priority';

  // Expansions
  @override String get expansionsTitle => 'Expansions';
  @override String get expansionBaseGame => 'Base game';
  @override String get expansionOwned => 'Owned';
  @override String get expansionAdd => 'Add to collection';
  @override String get expansionAdded => 'Added to collection';
  @override String get expansionNone => 'No expansions found on BGG';
  @override String get expansionNoBgg => 'Link game to BGG to browse expansions';
  @override String get expansionLinkToBgg => 'Search on BGG';
  @override String get filterGameType => 'Type';
  @override String get filterGameTypeBase => 'Base games';
  @override String get filterGameTypeExpansions => 'Expansions';
  @override String expansionOf(String name) => 'Expansion of: $name';
  @override String get sessionExpansionsSection => 'Expansions used';
  @override String get historyFilterWithExpansions => 'With expansions';
  @override String get statsMostUsedExpansion => 'Most used expansion';
  @override String get statsSessionsWithExpansions => 'Sessions with expansions';

  // Game Night Picker
  @override String get pickerTitle => 'Game Night Picker';
  @override String get pickerLandingTitle => 'What should we play?';
  @override String get pickerLandingSub => 'Find what fits your night';
  @override String get pickerPlayers => 'Number of players';
  @override String get pickerTime => 'Available time';
  @override String get pickerNoLimit => 'No limit';
  @override String get pickerComplexity => 'Complexity';
  @override String get pickerComplexityAny => 'Any';
  @override String get pickerComplexityLight => 'Light';
  @override String get pickerComplexityMedium => 'Medium';
  @override String get pickerComplexityHeavy => 'Heavy';
  @override String get pickerNotPlayedYet => 'Not played yet only';
  @override String get pickerFind => 'Find games';
  @override String get pickerNoResults => 'No games match the criteria';
  @override String get pickerRandomPick => 'Random pick';
  @override String get pickerPlay => 'Play!';
  @override String pickerResults(int n) => '$n game${n == 1 ? '' : 's'} match';
  @override String get pickerPickGame => 'Pick a game for me!';
  @override String get pickerCategories => 'Category';
  @override String get pickerMechanics => 'Mechanics';
  @override String get pickerFamilyFriendly => 'Family friendly (age ≤ 10)';
  @override String get pickerYearEra => 'Era';
  @override String get pickerYearClassic => 'Classic (≤ 2000)';
  @override String get pickerYearModern => 'Modern (2001–2015)';
  @override String get pickerYearRecent => 'Recent (2016+)';

  // Collection value
  @override String get catalogCollectionValue => 'Collection Value';
  @override String get catalogTotalSpent => 'Spent';
  @override String get catalogCurrentValue => 'Current value';
  @override String get catalogValueGain => 'Gain';
  @override String catalogGamesTracked(int n) => '$n game${n == 1 ? '' : 's'} tracked';

  // Purchase info
  @override String get addGamePurchaseSection => 'PURCHASE INFO';
  @override String get addGameBoughtPriceLabel => 'Bought price (empty = free / gift)';
  @override String get addGameCurrentPriceLabel => 'Current price';
  @override String get addGameAcquiredAtLabel => 'Acquired';
  @override String get addGameAcquiredAtNone => 'Not set';
  @override String get addGameSearchCurrentPrice => 'Search current price';
  @override String get addGameSealedLabel => 'Still sealed (in shrinkwrap)';

  // Game detail — price
  @override String get gameDetailBoughtPrice => 'Bought for';
  @override String get gameDetailCurrentPrice => 'Current price';
  @override String get gameDetailAcquiredAt => 'Acquired';
  @override String get gameDetailWithExpansions => 'With all expansions';
  @override String get gameDetailCostPerPlay => 'Cost per play';

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
  @override String get settingsDefaultPlayers => 'Default players';
  @override String get settingsDefaultPlayersHint => 'Add player name...';
  @override String get settingsDefaultPlayersAdd => 'Add';
  @override String get settingsDefaultPlayersEmpty => 'No saved players yet.';
  @override String get settingsTimerFeedback => 'Timer haptic feedback';
  @override String get settingsTimerFeedbackSub => 'Vibration on pause and end game';
  @override String get settingsQuickAdd => 'Quick add:';
  @override String get settingsAbout => 'ABOUT';
  @override String get settingsVersion => 'Version';
  @override String get settingsBggCredit => 'Board game data powered by BoardGameGeek';
  @override String get settingsBuiltWith => 'Built with Flutter ❤️';
  // Import
  @override String get settingsImport => 'IMPORT';
  @override String get importFullJson => 'Restore from JSON backup';
  @override String get importFullJsonSub => 'Import all data from a .json backup file';
  @override String get importSessions => 'Import sessions (CSV)';
  @override String get importSessionsSub => 'sessions.csv — adds missing sessions';
  @override String get importCollection => 'Import collection (CSV)';
  @override String get importCollectionSub => 'collection.csv — adds missing games';
  @override String get importWishlist => 'Import wishlist (CSV)';
  @override String get importWishlistSub => 'wishlist.csv — adds missing items';
  @override String get importReading => 'Reading file…';
  @override String importJsonResult(int games, int sessions, int wishlist) =>
      'Imported: $games game${games == 1 ? '' : 's'}, $sessions session${sessions == 1 ? '' : 's'}, $wishlist wishlist item${wishlist == 1 ? '' : 's'}.';
  @override String importCsvResult(int added, int skipped) =>
      '$added added, $skipped already exist.';
  @override String get importError => 'Could not read file. Make sure it is a valid export.';
  @override String get importNoFile => 'No file selected.';

  @override String get settingsExport => 'EXPORT';
  @override String get exportFullJson => 'Full backup (JSON)';
  @override String get exportFullJsonSub => 'All data in one .json file';
  @override String get exportFullZip => 'Full backup (ZIP)';
  @override String get exportFullZipSub => 'JSON + all CSVs in one archive';
  @override String get exportIndividual => 'Individual CSV files';
  @override String get exportSessions => 'Sessions';
  @override String get exportCollection => 'Collection';
  @override String get exportWishlist => 'Wishlist';
  @override String get exportStatistics => 'Statistics';
  @override String get exportPreparing => 'Preparing export…';
  @override String get exportDone => 'Export ready';
  @override String get settingsCurrency => 'Currency';
  @override String get settingsPriceSearch => 'Price search engine';

  // BGG Account
  @override String get settingsBgg => 'BGG ACCOUNT';
  @override String get settingsBggUsername => 'BGG Username';
  @override String get settingsBggUsernameHint => 'Enter your BGG username';
  @override String get settingsBggSync => 'Sync collection';
  @override String get settingsBggSyncing => 'Syncing…';
  @override String settingsBggSyncResult(int added, int skipped) =>
      '$added game${added == 1 ? '' : 's'} added, $skipped already in collection.';
  @override String get settingsBggSyncError => 'Sync failed. Check your username and connection.';
  @override String get settingsBggUserNotFound => 'BGG user not found or collection is empty.';
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
  @override String get filterGame => 'Gra';
  @override String get filterPlayer => 'Gracz';

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
  @override String get catalogTabCollection => 'Kolekcja';
  @override String get catalogTabWishlist => 'Życzenia';
  @override String get catalogSortAZ => 'A → Z';
  @override String get catalogSortZA => 'Z → A';
  @override String get catalogSortRecentlyAdded => 'Ostatnio dodane';
  @override String get catalogSortMyRating => 'Moja ocena';
  @override String get historySortNewest => 'Najnowsze';
  @override String get historySortOldest => 'Najstarsze';
  @override String get historySortByGame => 'Po nazwie gry';

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
  @override String get rematch => 'Rewanż';
  @override String get gameResultsTitle => 'Wyniki gry';
  @override String get gameResultsClose => 'Zamknij';
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
  @override String get sessionLocationLabel => 'Lokalizacja (opcjonalnie)';
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
  @override String get sessionDetailTiebreaker => 'Rozstrzygnięcie';
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
  @override String get statsPresetAllTime => 'Cały czas';
  @override String get statsPresetLast30 => 'Ostatnie 30 dni';
  @override String get statsPresetLast3m => 'Ostatnie 3 miesiące';
  @override String get statsPresetLast6m => 'Ostatnie 6 miesięcy';
  @override String get statsPresetThisYear => 'Ten rok';
  @override String get statsPresetCustom => 'Niestandardowy';
  @override String get statsFilterFrom => 'Od';
  @override String get statsFilterTo => 'Do';
  @override String get statsHeadToHead => 'Twarzą w twarz';
  @override String get statsSelectPlayer => 'Wybierz gracza...';
  @override String get statsViewRivalry => 'Porównaj';
  @override String get statsTogetherSessions => 'Razem';
  @override String get statsDraws => 'Remisy';
  @override String get statsNeverPlayedTogether => 'Ci gracze nigdy razem nie grali.';

  // Teams
  @override String get teamGame => 'Gra drużynowa';
  @override String get teamGameSub => 'Gracze grają w drużynach';
  @override String get teamCount => 'Liczba drużyn';
  @override String teamNameHint(int n) => 'Drużyna $n';
  @override String get teamAssign => 'Drużyna';
  @override String get statsBestTeams => 'NAJLEPSZE DRUŻYNY';
  @override String get statsBestPartner => 'Najlepszy partner';
  @override String get statsWorstPartner => 'Najgorszy partner';
  @override String get statsPartnerSessions => 'Sesje razem';
  @override String get statsPartnerWins => 'Wygrane razem';
  @override String get statsHeatmap => 'AKTYWNOŚĆ';
  @override String get statsHeatmapLess => 'Mniej';
  @override String get statsHeatmapMore => 'Więcej';

  // Wishlist
  @override String get navWishlist => 'Życzenia';
  @override String get wishlistTitle => 'Lista życzeń';
  @override String get wishlistEmpty => 'Twoja lista życzeń jest pusta.';
  @override String get wishlistAddItem => 'Dodaj do listy';
  @override String get wishlistAddTitle => 'Dodaj do listy życzeń';
  @override String get wishlistEditTitle => 'Edytuj pozycję';
  @override String get wishlistNameLabel => 'Nazwa gry *';
  @override String get wishlistNoteLabel => 'Notatka (opcjonalnie)';
  @override String get wishlistNoteHint => 'np. "Poczekaj na wyprzedaż", "Poproś na urodziny"...';
  @override String get wishlistPriority => 'Priorytet';
  @override String get wishlistPriorityLow => 'Niski';
  @override String get wishlistPriorityMedium => 'Średni';
  @override String get wishlistPriorityHigh => 'Wysoki';
  @override String get wishlistMoveToCollection => 'Przenieś do kolekcji';
  @override String get wishlistMoveConfirmTitle => 'Przenieść do kolekcji?';
  @override String wishlistMoveConfirmContent(String name) =>
      '"$name" zostanie dodana do kolekcji i usunięta z listy życzeń.';
  @override String get wishlistDeleteTitle => 'Usunąć z listy życzeń?';
  @override String wishlistDeleteContent(String name) =>
      'Usunąć "$name" z listy życzeń?';
  @override String get wishlistBggFilled => 'Szczegóły pobrane z BGG';
  @override String get wishlistSave => 'Zapisz';
  @override String get wishlistPriceLabel => 'Docelowa cena (opcjonalnie)';
  @override String get wishlistSearchOnline => 'Szukaj online';
  @override String get wishlistSearchSuffix => 'gra planszowa';
  @override String get wishlistSortPriority => 'Priorytet (wysoki najpierw)';
  @override String get wishlistSortPriceLow => 'Cena: niska → wysoka';
  @override String get wishlistSortPriceHigh => 'Cena: wysoka → niska';
  @override String get wishlistNoResults => 'Żadne pozycje nie pasują do filtrów.';
  @override String get wishlistClearFilters => 'Wyczyść filtry';
  @override String get wishlistFilterByPriority => 'Filtruj po priorytecie';

  // Expansions
  @override String get expansionsTitle => 'Rozszerzenia';
  @override String get expansionBaseGame => 'Gra podstawowa';
  @override String get expansionOwned => 'Posiadane';
  @override String get expansionAdd => 'Dodaj do kolekcji';
  @override String get expansionAdded => 'Dodano do kolekcji';
  @override String get expansionNone => 'Brak rozszerzeń na BGG';
  @override String get expansionNoBgg => 'Połącz grę z BGG, aby przeglądać rozszerzenia';
  @override String get expansionLinkToBgg => 'Szukaj na BGG';
  @override String get filterGameType => 'Typ';
  @override String get filterGameTypeBase => 'Gry podstawowe';
  @override String get filterGameTypeExpansions => 'Rozszerzenia';
  @override String expansionOf(String name) => 'Rozszerzenie gry: $name';
  @override String get sessionExpansionsSection => 'Użyte rozszerzenia';
  @override String get historyFilterWithExpansions => 'Z rozszerzeniami';
  @override String get statsMostUsedExpansion => 'Najczęściej używane rozszerzenie';
  @override String get statsSessionsWithExpansions => 'Sesje z rozszerzeniami';

  // Game Night Picker
  @override String get pickerTitle => 'Dobieracz gry';
  @override String get pickerLandingTitle => 'W co zagramy?';
  @override String get pickerLandingSub => 'Znajdź coś na dziś wieczór';
  @override String get pickerPlayers => 'Liczba graczy';
  @override String get pickerTime => 'Dostępny czas';
  @override String get pickerNoLimit => 'Bez limitu';
  @override String get pickerComplexity => 'Złożoność';
  @override String get pickerComplexityAny => 'Dowolna';
  @override String get pickerComplexityLight => 'Lekka';
  @override String get pickerComplexityMedium => 'Średnia';
  @override String get pickerComplexityHeavy => 'Ciężka';
  @override String get pickerNotPlayedYet => 'Tylko niegrane';
  @override String get pickerFind => 'Znajdź gry';
  @override String get pickerNoResults => 'Żadna gra nie pasuje do kryteriów';
  @override String get pickerRandomPick => 'Losowy wybór';
  @override String get pickerPlay => 'Graj!';
  @override String get pickerPickGame => 'Wybierz grę za mnie!';
  @override String get pickerCategories => 'Kategoria';
  @override String get pickerMechanics => 'Mechaniki';
  @override String get pickerFamilyFriendly => 'Familijne (wiek ≤ 10)';
  @override String get pickerYearEra => 'Era';
  @override String get pickerYearClassic => 'Klasyczne (≤ 2000)';
  @override String get pickerYearModern => 'Nowoczesne (2001–2015)';
  @override String get pickerYearRecent => 'Najnowsze (2016+)';
  @override String pickerResults(int n) {
    if (n == 1) return '1 gra pasuje';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return '$n gry pasują';
    return '$n gier pasuje';
  }

  // Collection value
  @override String get catalogCollectionValue => 'Wartość kolekcji';
  @override String get catalogTotalSpent => 'Wydano';
  @override String get catalogCurrentValue => 'Wartość aktualna';
  @override String get catalogValueGain => 'Zysk';
  @override String catalogGamesTracked(int n) {
    if (n == 1) return '1 gra śledzona';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return '$n gry śledzone';
    return '$n gier śledzonych';
  }

  // Purchase info
  @override String get addGamePurchaseSection => 'INFORMACJE O ZAKUPIE';
  @override String get addGameBoughtPriceLabel => 'Cena zakupu (puste = prezent / darmowa)';
  @override String get addGameCurrentPriceLabel => 'Cena aktualna';
  @override String get addGameAcquiredAtLabel => 'Data nabycia';
  @override String get addGameAcquiredAtNone => 'Nie ustawiono';
  @override String get addGameSearchCurrentPrice => 'Szukaj aktualnej ceny';
  @override String get addGameSealedLabel => 'Nadal w folii (folia ochronna)';

  // Game detail — price
  @override String get gameDetailBoughtPrice => 'Kupiona za';
  @override String get gameDetailCurrentPrice => 'Cena aktualna';
  @override String get gameDetailAcquiredAt => 'Data nabycia';
  @override String get gameDetailWithExpansions => 'Z wszystkimi rozszerzeniami';
  @override String get gameDetailCostPerPlay => 'Koszt za partię';

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
  @override String get settingsDefaultPlayers => 'Domyślni gracze';
  @override String get settingsDefaultPlayersHint => 'Dodaj imię gracza...';
  @override String get settingsDefaultPlayersAdd => 'Dodaj';
  @override String get settingsDefaultPlayersEmpty => 'Brak zapisanych graczy.';
  @override String get settingsTimerFeedback => 'Wibracje timera';
  @override String get settingsTimerFeedbackSub => 'Wibracje przy pauzie i końcu gry';
  @override String get settingsQuickAdd => 'Szybkie dodanie:';
  @override String get settingsAbout => 'O APLIKACJI';
  @override String get settingsVersion => 'Wersja';
  @override String get settingsBggCredit => 'Dane gier dostarczone przez BoardGameGeek';
  @override String get settingsBuiltWith => 'Stworzone z Flutter ❤️';
  // Import
  @override String get settingsImport => 'IMPORT';
  @override String get importFullJson => 'Przywróć z kopii zapasowej (JSON)';
  @override String get importFullJsonSub => 'Importuj wszystkie dane z pliku .json';
  @override String get importSessions => 'Importuj sesje (CSV)';
  @override String get importSessionsSub => 'sessions.csv — dodaje brakujące sesje';
  @override String get importCollection => 'Importuj kolekcję (CSV)';
  @override String get importCollectionSub => 'collection.csv — dodaje brakujące gry';
  @override String get importWishlist => 'Importuj listę życzeń (CSV)';
  @override String get importWishlistSub => 'wishlist.csv — dodaje brakujące pozycje';
  @override String get importReading => 'Wczytywanie pliku…';
  @override String importJsonResult(int games, int sessions, int wishlist) {
    String g;
    if (games == 1) g = '1 gra';
    else if (games % 10 >= 2 && games % 10 <= 4 && (games % 100 < 10 || games % 100 >= 20)) g = '$games gry';
    else g = '$games gier';
    return 'Zaimportowano: $g, $sessions sesji, $wishlist życzeń.';
  }
  @override String importCsvResult(int added, int skipped) =>
      '$added dodano, $skipped już istnieje.';
  @override String get importError => 'Nie można odczytać pliku. Upewnij się, że to poprawny eksport.';
  @override String get importNoFile => 'Nie wybrano pliku.';

  @override String get settingsExport => 'EKSPORT';
  @override String get exportFullJson => 'Pełna kopia zapasowa (JSON)';
  @override String get exportFullJsonSub => 'Wszystkie dane w jednym pliku .json';
  @override String get exportFullZip => 'Pełna kopia zapasowa (ZIP)';
  @override String get exportFullZipSub => 'JSON + wszystkie CSV w jednym archiwum';
  @override String get exportIndividual => 'Pojedyncze pliki CSV';
  @override String get exportSessions => 'Sesje';
  @override String get exportCollection => 'Kolekcja';
  @override String get exportWishlist => 'Lista życzeń';
  @override String get exportStatistics => 'Statystyki';
  @override String get exportPreparing => 'Przygotowywanie eksportu…';
  @override String get exportDone => 'Eksport gotowy';
  @override String get settingsCurrency => 'Waluta';
  @override String get settingsPriceSearch => 'Wyszukiwarka cen';

  // BGG Account
  @override String get settingsBgg => 'KONTO BGG';
  @override String get settingsBggUsername => 'Nazwa użytkownika BGG';
  @override String get settingsBggUsernameHint => 'Wpisz swoją nazwę użytkownika BGG';
  @override String get settingsBggSync => 'Synchronizuj kolekcję';
  @override String get settingsBggSyncing => 'Synchronizuję…';
  @override String settingsBggSyncResult(int added, int skipped) {
    String addedStr;
    if (added == 1) addedStr = '1 gra dodana';
    else if (added % 10 >= 2 && added % 10 <= 4 && (added % 100 < 10 || added % 100 >= 20)) addedStr = '$added gry dodane';
    else addedStr = '$added gier dodanych';
    return '$addedStr, $skipped już w kolekcji.';
  }
  @override String get settingsBggSyncError => 'Synchronizacja nie powiodła się. Sprawdź nazwę i połączenie.';
  @override String get settingsBggUserNotFound => 'Nie znaleziono użytkownika BGG lub kolekcja jest pusta.';
}
