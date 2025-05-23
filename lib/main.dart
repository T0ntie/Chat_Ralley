import 'package:flutter/material.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/action_observer.dart';
import 'package:hello_world/gui/chat/chat_page.dart';
import 'package:hello_world/gui/credits_screen.dart';
import 'package:hello_world/gui/debuging_panel.dart';
import 'package:hello_world/gui/game_map_widget.dart';
import 'package:hello_world/gui/item_button.dart';
import 'package:hello_world/gui/notification_services.dart';
import 'package:hello_world/gui/open_qr_scan_dialog_intent.dart';
import 'package:hello_world/gui/side_panel.dart';
import 'package:hello_world/gui/splash.dart';
import 'package:hello_world/services/gpt_utilities.dart';
import 'services/location_service.dart';
import 'services/compass_service.dart';
import 'engine/game_engine.dart';
import 'app_resources.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

void main() async {
  await dotenv.load(fileName: ".env"); // lädt die .env-Datei
  WidgetsFlutterBinding.ensureInitialized();
  GptUtilities.init();

  // Nur Hochformat erlauben
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<MyHomePageState> homePageKey = GlobalKey<MyHomePageState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const String title = 'StoryTrail';

  @override
  State<MyApp> createState() => _MyAppState();
}

enum AppScreen { splash, home, credits }

class _MyAppState extends State<MyApp> {
  AppScreen _currentScreen = AppScreen.splash;
  //bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_currentScreen) {
      case AppScreen.splash:
        screen = SplashScreen(
          onContinue: () {
            setState(() {
              _currentScreen = AppScreen.home;
            });
          },
        );
        break;
      case AppScreen.home:
        screen = MyHomePage(key: homePageKey, title: MyApp.title);
        break;
      case AppScreen.credits:
        screen = CreditsScreen();
        break;
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _frameRate = Duration(milliseconds: 33);

  //final String title = "StoryTrail";
  //LatLng _playerPosition = LatLng(51.5074, -0.1278); // Beispiel für London
  bool _locationServiceInitialized = false;
  bool _gameInitialized = false;
  String? _initializationError;
  bool _initializationCompleted = false;

  double _currentHeading = 0.0;
  DateTime _lastHeadingUpdateTime = DateTime.now();
  final MapController _mapController = MapController();
  double _currentMapRotation = 0.0;
  late final StreamSubscription<MapEvent> _mapControllerSubscription;
  late final StreamSubscription<double> _compassSubscription;
  late final StreamSubscription<Position> _positionSubscription;

  List<Item> get _items => GameEngine().items;

  late final Timer _updateTimer;

  bool _isMapHeadingBasedOrientation = false;

  bool get _isSimulatingLocation => GameEngine().isGPSSimulating;
  bool _debuggingVisible = false;

  bool showActionTestingPanel = false;

  set _isSimulatingLocation(bool value) {
    GameEngine().isGPSSimulating = value;
  }

  LatLng? _lastRealGpsPosition;

  bool _isSidePanelVisible = false; //fixme

  void _centerMapOnCurrentLocation() {
    _mapController.move(GameEngine().playerPosition, 16.0);
  }

  void _switchMapOrientationMode() {
    _isMapHeadingBasedOrientation = !_isMapHeadingBasedOrientation;
    _mapController.rotate(_isMapHeadingBasedOrientation ? _currentHeading : 0);
    _currentMapRotation = 0;
  }

  Future<void> _initializeGame() async {
    await GameEngine().initializeGame();
    _gameInitialized = true;
    _checkIfInitializationCompleted();
    SnackBarService.showSuccessSnackBar(context, "✔️ Alle Spieldaten geladen");
  }

  void _checkIfInitializationCompleted() {
    if (_gameInitialized &&
        _locationServiceInitialized &&
        !_initializationCompleted) {
      setState(() {
        _initializationCompleted = true;
      });
      GameEngine().registerInitialization();
    }
  }

  Future<void> _initializeLocationStream() async {
    await LocationService.initialize();
    _positionSubscription = LocationService.getPositionStream().listen((
      Position position,
    ) {
      if (!_isSimulatingLocation) {
        GameEngine().playerPosition = LatLng(
          position.latitude,
          position.longitude,
        );
      }
      _locationServiceInitialized = true;
      _checkIfInitializationCompleted();
    });
  }

  void _initializeMapController() {
    _mapControllerSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate) {
        setState(() {
          _currentMapRotation = event.camera.rotation;
        });
      }
    });
  }

  Future<void> _initializeCompassStream() async {
    try {
      CompassService.initialize();
    } catch (e) {
      rethrow;
    } //
    _compassSubscription = CompassService.getCompassDirection().listen((
      heading,
    ) {
      DateTime currentTime = DateTime.now();
      if ((heading - _currentHeading).abs() >= 5 ||
          currentTime.difference(_lastHeadingUpdateTime).inSeconds >= 1) {
        if (_isMapHeadingBasedOrientation) {
          _mapController.rotate(-heading);
        }
        setState(() {
          _currentHeading = heading;
          _lastHeadingUpdateTime = currentTime;
        });
      }
    });
  }

  void _initializeUpdateTimer() {
    _updateTimer = Timer.periodic(_frameRate, (timer) {
      if (_initializationCompleted) {
        if (GameEngine().isGPSSimulating) {
          GameEngine().updatePlayerPositionSimulated();
        }
        GameEngine().updateAllNpcPositions();
        setState(() {});
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _initializeGame();
    } catch (e) {
      _initializationError = '❌ Initialisierung der Spieldaten fehlgeschlagen.';
      SnackBarService.showErrorSnackBar(context, _initializationError!);
      return;
    }

    try {
      await Future.wait([
        _initializeCompassStream(),
        _initializeLocationStream(),
      ]);
    } catch (e) {
      _initializationError =
          '❌ Initialisieren der Standortbestimmung fehlgeschlagen.';
      SnackBarService.showErrorSnackBar(context, _initializationError!);
      return;
    }

    try {
      _initializeMapController();
    } catch (e) {
      _initializationError = '❌ Initialisieren der Karte fehlgeschlagen.';
      SnackBarService.showErrorSnackBar(context, _initializationError!);
      return;
    }

    _initializeUpdateTimer();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Positioned buildMapOrientationModeButton() {
    return (Positioned(
      top: 40, // Abstand vom oberen Rand
      right: 20, // Abstand vom rechten Rand

      child: FloatingActionButton(
        heroTag: "MapOrientation_fab",
        onPressed: () {
          setState(() {
            _switchMapOrientationMode();
          });
        },
        backgroundColor: Colors.transparent,
        // Macht den Hintergrund transparent
        elevation: 0,
        // Entfernt den Schatten
        child: AppIcons.mapHeading(context, _isMapHeadingBasedOrientation),
      ),
    ));
  }

  Widget buildFloatingActionButton() {
    return GestureDetector(
      onTap:
          _initializationCompleted
              ? () {
                setState(() {
                  _centerMapOnCurrentLocation();
                });
              }
              : null,
      onLongPress:
          _initializationCompleted && _isSimulatingLocation
              ? () {
                GameEngine().playerMovementController!.teleportHome();
                _centerMapOnCurrentLocation();
              }
              : null,
      child: FloatingActionButton(
        heroTag: "CenterLocation_fab",
        onPressed: null, // wichtig, damit GestureDetector alles übernimmt
        child: AppIcons.centerLocation(context),
      ),
    );
  }

  /*return (FloatingActionButton(
      heroTag: "CenterLocation_fab",

      onPressed:
          _initializationCompleted
              ? () {
                setState(() {
                  // Wenn der Button gedrückt wird, zentrieren wir die Karte auf den aktuellen Standort
                  _centerMapOnCurrentLocation();
                });
              }
              : null,
      child: AppIcons.centerLocation(
        context,
      ), // Zeigt ein Symbol für den "Mein Standort"-Button
    ));*/
  //}

  List<ItemButton> buildItems() {
    return _items.where((i) => i.isOwned).map((item) {
      return ItemButton(item: item);
    }).toList();
  }

/*
  void _moveSimulatedLocation(double x, double y) {
    setState(() {
      GameEngine().playerPosition = LatLng(
        GameEngine().playerPosition.latitude + x,
        GameEngine().playerPosition.longitude + y,
      );
    });
    //_processNewLocation(_playerPosition);
  }
*/

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey.shade900,
          elevation: 4,
          foregroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // oder dein gewählter Hintergrund
                borderRadius: BorderRadius.circular(12),
                // 8–16 ist typisch für Android-Icons
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4.0),
              width: 40,
              height: 40,
              child: Image.asset(
                'assets/logo/StoryTrail.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcons.error(context),
                //Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Fehler bei der Initialisierung',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _initializationError!,
                  style: TextStyle(color: ResourceColors.errorMessage(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initializationError = null;
                      _initializationCompleted = false;
                      _gameInitialized = false;
                      _locationServiceInitialized = false;
                    });
                    _initializeApp();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Erneut versuchen"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 4,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),

          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _debuggingVisible = !_debuggingVisible; // Beispielzustand
              });
            },

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // oder dein gewählter Hintergrund
                borderRadius: BorderRadius.circular(12),
                // 8–16 ist typisch für Android-Icons
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4.0),
              width: 40,
              height: 40,
              child: Image.asset(
                'assets/logo/StoryTrail.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Text(
          "StoryTrail",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_debuggingVisible)
            IconButton(
              icon: Icon(Icons.bug_report),
              tooltip: "Test Actions",
              onPressed: () {
                setState(() {
                  showActionTestingPanel = !showActionTestingPanel;
                });
              },
            ),
          if (_debuggingVisible)
            IconButton(
              icon: Icon(Icons.gps_off),
              tooltip: "Simulate",
              onPressed: () {
                setState(() {
                  if (!_isSimulatingLocation) {
                    _lastRealGpsPosition = GameEngine().playerPosition;
                    GameEngine().playerMovementController?.teleportTo(
                      _lastRealGpsPosition!,
                    );
                  } else {
                    if (_lastRealGpsPosition != null) {
                      GameEngine().setRealGpsPositionAndNotify(
                        _lastRealGpsPosition!,
                      );
                    }
                  }
                  _isSimulatingLocation = !_isSimulatingLocation;
                });
              },
            ),
          if (_debuggingVisible)
            IconButton(
            icon: Icon(Icons.restart_alt),
            tooltip: "Restart",
            onPressed: () async {
              GameEngine().reset();
              await GameEngine().initializeGame();
              final currentPosition = GameEngine().playerPosition;
              GameEngine().setRealGpsPositionAndNotify(currentPosition);
              GameEngine().registerInitialization();
            },
          ),
          IconButton(
            icon: Icon(Icons.menu_open),
            tooltip: "Inventar öffnen",
            onPressed: () {
              setState(() {
                _isSidePanelVisible = !_isSidePanelVisible;
              });
            },
          ),
        ],
      ),

      body:
          !_initializationCompleted
              ? Center(
                child: CircularProgressIndicator(),
              ) // Ladeanzeige, wenn der Standort noch nicht verfügbar ist
              : Stack(
                children: [
                  GameMapWidget(
                    location: GameEngine().playerPosition,
                    mapController: _mapController,
                    currentHeading: _currentHeading,
                    currentMapRotation: _currentMapRotation,
                    isMapHeadingBasedOrientation: _isMapHeadingBasedOrientation,
                    isSimulatingLocation: _isSimulatingLocation,
                    onSimulatedLocationChange: (point) {
                      setState(() {
                        GameEngine().playerPosition = point;
                        //_processNewLocation(_playerPosition);
                      });
                    },
                    onNpcChatRequested: (npc) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatPage(npc: npc)),
                      );
                    },
                  ),
                  buildMapOrientationModeButton(),
                  if (showActionTestingPanel)
                    ActionTestingPanel(
                      actionsByTrigger:
                          GameEngineDebugger.getActionsGroupedByTrigger(),
                      flags: GameEngine().flags,
                    ),
                  SidePanel(
                    isVisible: (_isSidePanelVisible),
                    onClose: () {
                      setState(() {
                        _isSidePanelVisible = false;
                        GameEngine().markAllItemsAsSeen();
                      });
                    },
                    onScan: () {
                      setState(() {
                        print("text");
                        OpenScanDialogIntent(
                          title: "Fund erfassen",
                          expectedItems: GameEngine().getScannableItems(),
                        ).call(context);
                      });
                    },

                    children: buildItems(),
                  ),
                ],
              ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  void checkForNewItemsWithDelay() async {
    print("👉 Check for new items triggered");

    // Prüfen, ob neue Items vorhanden sind
    if (!_isSidePanelVisible && GameEngine().hasNewItems()) {
      await Future.delayed(Duration(seconds: 3));
      if (!mounted) return;
      print("👉 New items found, opening side panel");
      setState(() {
        _isSidePanelVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _mapControllerSubscription.cancel();
    _compassSubscription.cancel();
    _positionSubscription.cancel();
    _updateTimer.cancel();
    super.dispose();
  }
}
