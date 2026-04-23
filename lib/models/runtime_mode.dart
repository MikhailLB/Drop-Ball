enum RuntimeMode {
  browser,
  arcade,
  undetermined;

  String toStoreString() {
    switch (this) {
      case RuntimeMode.browser:
        return 'browser';
      case RuntimeMode.arcade:
        return 'arcade';
      case RuntimeMode.undetermined:
        return 'undetermined';
    }
  }

  static RuntimeMode parse(String? raw) {
    switch (raw) {
      case 'browser':
      case 'online':
        return RuntimeMode.browser;
      case 'arcade':
      case 'offline':
        return RuntimeMode.arcade;
      default:
        return RuntimeMode.undetermined;
    }
  }
}
