import 'package:flutter/material.dart';
import 'package:storytrail/gui/game_screen.dart';
import '../gui/action_observer.dart';
import '../gui/credits_screen.dart';
import '../gui/trail_selection.dart';
import '../services/gpt_utilities.dart';
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

  try {
    await Firebase.initializeApp();
    print("✅ Firebase erfolgreich initialisiert");
  } catch (e) {
    print("❌ Firebase Fehler: $e");
    rethrow;
  }

  if (kDebugMode) {
    // Wenn wir im Debug-Modus sind, aktiviere App Check mit dem Debug Provider.
    // Dies generiert das Token im Logcat/Konsole, das du registrieren musst.
    print("⚠️ App Check: Debug Provider wird initialisiert...");
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print("✅ App Check Debug Provider aktiviert.");
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    print("✅ App Check Production Provider aktiviert.");
  }

  GptUtilities.init();

  // Nur Hochformat erlauben
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GameEngine().loadTrails();
  print("✅ trails should be loaded");

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<GameScreenState> homePageKey = GlobalKey<GameScreenState>();

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

  @override
  void initState() {
    super.initState();
    //_currentScreen = AppScreen.loading;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([LocationService.initialize()]);
      Position pos = await Geolocator.getCurrentPosition();
      GameEngine().playerPosition = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentScreen = AppScreen.trails;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Fehler beim Initialisieren: $e';
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
      navigatorObservers: [ActionObserver()],
      title: MyApp.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ResourceColors.seed),
      ),
      home: screen,
    );
  }
}
