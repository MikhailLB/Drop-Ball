enum AppMode {
  browser,
  arcade,
  undetermined;

  String toStoreString() {
    switch (this) {
      case AppMode.browser:
        return 'browser';
      case AppMode.arcade:
        return 'arcade';
      case AppMode.undetermined:
        return 'undetermined';
    }
  }

  static AppMode parse(String? raw) {
    switch (raw) {
      case 'browser':
      case 'online':
        return AppMode.browser;
      case 'arcade':
      case 'offline':
        return AppMode.arcade;
      default:
        return AppMode.undetermined;
    }
  }
}
