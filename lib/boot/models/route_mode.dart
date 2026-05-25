enum RouteMode {
  web,
  arcade,
  pristine;

  static RouteMode fromString(String? v) => switch (v) {
    'web'    => RouteMode.web,
    'arcade' => RouteMode.arcade,
    _        => RouteMode.pristine,
  };

  String toKey() => switch (this) {
    RouteMode.web     => 'web',
    RouteMode.arcade  => 'arcade',
    RouteMode.pristine => 'pristine',
  };
}
