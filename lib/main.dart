import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'package:storytrail/gui/credits_screen.dart';
import 'package:storytrail/gui/location_stream_manager.dart';
import 'package:storytrail/gui/trail_selection_screen.dart';
import 'package:storytrail/services/gpt_utilities.dart';
import 'package:storytrail/services/log_service.dart';
import 'services/location_service.dart';
import 'engine/game_engine.dart';
import 'app_resources.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint = (String? message, {int? wrapWidth}) {};

  try {
    await Firebase.initializeApp();
    log.i("✅ Firebase erfolgreich initialisiert");
  } catch (e, stackTrace) {
    log.e("❌ Failed to initialize Firebase", error: e, stackTrace: stackTrace);
    rethrow;
  }

  if (kDebugMode) {
    // Wenn wir im Debug-Modus sind, aktiviere App Check mit dem Debug Provider.
    // Dies generiert das Token im Logcat/Konsole, das du registrieren musst.
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    log.i("✅ App Check Debug Provider aktiviert.");
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    log.i("✅ App Check Production Provider aktiviert.");
  }

  //firebase anonymouse login
  try {
    initAnonymousUser();
  } catch(e, stackTrace) {
    log.e("❌ Failed to initialize anonymous user:", error: e, stackTrace: stackTrace);
  }

  try {
    GptUtilities.init();
  } catch(e, stackTrace) {
    log.e("❌ Failed initialize GPT Utilities:", error: e, stackTrace: stackTrace);
  }

  // Nur Hochformat erlauben
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  LocationStreamManager().initialize(); // nur einmal starten

  try {
    await GameEngine().loadTrails();
    log.i("✅ Trails erfolgreich geladen");
  } catch(e, stackTrace) {
    log.e("❌ Failed load existing trails:", error: e, stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<GameScreenState> homePageKey = GlobalKey<GameScreenState>();
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>(); //fixme ist vielleicht eine Sackgasse

Future<void> initAnonymousUser() async {
  final auth = FirebaseAuth.instance;

  // Prüfen, ob der Nutzer bereits eingeloggt ist
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  // UID holen
  final uid = auth.currentUser!.uid;
  GameEngine().playerId = uid;
  log.i('✅ Angemeldet mit UID: $uid');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const String title = 'StoryTrail';

  @override
  State<MyApp> createState() => _MyAppState();
}

enum AppScreen { loading, trails, game, credits, error }

class _MyAppState extends State<MyApp> {
  AppScreen _currentScreen = AppScreen.loading;
  String? _errorMessage;
  late final StreamSubscription<Position> _positionSubscription;
  bool get _isSimulatingLocation => GameEngine().isGPSSimulating;


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {

      final stream = LocationService.stream;
      if (stream != null) {
        _positionSubscription = stream.listen((position) {
          if (!_isSimulatingLocation) {
            GameEngine().playerPosition = LatLng(position.latitude, position.longitude);
          }
        });
      } else {
        log.w("⚠️ Kein aktiver Standortstream – Manager noch nicht initialisiert?");
        assert(false, "⚠️ Kein aktiver Standortstream – Manager noch nicht initialisiert?");
      }
      setState(() {
        _currentScreen = AppScreen.trails;
      });
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = '❌ Fehler beim Initialisieren';
        log.e("❌ Fehler beim Initialisieren", error: e, stackTrace: stackTrace);
        _currentScreen = AppScreen.error;
      });
    }
  }

  String? _selectedTrailId;

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_currentScreen) {
      case AppScreen.loading:
        screen = const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
        break;
      case AppScreen.trails:
        screen = TrailSelectionScreen(
          onTrailSelected: (String trailId) {
            setState(() {
              _selectedTrailId = trailId;
              _currentScreen = AppScreen.game;
            });
          },
          availableTrails: GameEngine().trailsList,
        );
        break;
      case AppScreen.game:
        screen = GameScreen(
          key: homePageKey,
          title: MyApp.title,
          trailId: _selectedTrailId!,
          onFatalError: (error) {
            setState(() {
              _errorMessage = error;
              _currentScreen = AppScreen.error;
            });
          },
        );
        break;
      case AppScreen.credits:
        screen = CreditsScreen(
          onFatalError: (error) {
            setState(() {
              _errorMessage = error;
              _currentScreen = AppScreen.error;
            });
          },
        );
        break;
      case AppScreen.error:
        screen = Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Hintergrundbild
              Image.asset('assets/images/error.png', fit: BoxFit.cover),

              // UI im Vordergrund
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'Unbekannter Fehler',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentScreen = AppScreen.loading;
                          _errorMessage = null;
                        });
                        _initializeApp();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      title: MyApp.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ResourceColors.seed),
      ),
      home: screen,
    );
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    super.dispose();
  }
}