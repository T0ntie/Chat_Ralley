class EnvironmentConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static String get firebaseHostingUri {
    switch (flavor) {
      case 'dev':
        return 'https://aitrailsgo-dev.web.app/';
      case 'prod':
        return 'https://aitrailsgo.web.app/';
      default:
        throw Exception('Unknown flavor: $flavor');
    }
  }

  static bool runningOnDev() {
    return flavor == 'dev';
  }

  static bool runningOnProd() {
    return flavor == 'prod';
  }

  static String get appTitle {
    print("getting app title");
    switch (flavor) {
      case 'dev':
        return 'AI Trails GO - DEV';
      case 'prod':
        return 'AI Trails GO';
      default:
        throw Exception('Unknown flavor: $flavor');
    }
  }
}
