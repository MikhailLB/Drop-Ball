/// Persisted routing decision for each launch.
///
/// - [web]   → open the WebView (returning user with saved URL).
/// - [game]  → open the Drop Ball game (organic / unattributed user).
/// - [fresh] → no decision yet; full attribution pipeline runs.
enum AppRoute {
  web,
  game,
  fresh;

  String toKey() => switch (this) {
    AppRoute.web   => 'web',
    AppRoute.game  => 'game',
    AppRoute.fresh => 'fresh',
  };

  static AppRoute fromKey(String? raw) => switch (raw) {
    'web' || 'browser' => AppRoute.web,
    'game' || 'arcade' => AppRoute.game,
    _                  => AppRoute.fresh,
  };
}
