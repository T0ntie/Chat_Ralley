import 'package:flutter/material.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/chat/chat_page.dart';
import 'package:hello_world/gui/debuging_panel.dart';
import 'package:hello_world/gui/game_map_widget.dart';
import 'package:hello_world/gui/item_button.dart';
import 'package:hello_world/gui/joystick_overlay.dart';
import 'package:hello_world/gui/notification_services.dart';
import 'package:hello_world/gui/side_panel.dart';
import 'services/location_service.dart';
import 'services/compass_service.dart';
import 'engine/npc.dart';
import 'engine/game_engine.dart';
import 'engine/hotspot.dart';
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

  // Nur Hochformat erlauben
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String title = 'StoryTrail';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ResourceColors.seed),
      ),
      home: const MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _frameRate = Duration(milliseconds: 33);

  //final String title = "StoryTrail";
  LatLng _playerPosition = LatLng(51.5074, -0.1278); // Beispiel für London
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

  List<Npc> get _npcs => GameEngine().npcs;

  List<Item> get _items => GameEngine().items;

  List<Hotspot> get _hotspots => GameEngine().hotspots;
  late final Timer _updateTimer;

  bool _isMapHeadingBasedOrientation = false;

  bool get _isSimulatingLocation => GameEngine().isTestSimimulationOn;

  bool showActionTestingPanel = false;

  set _isSimulatingLocation(bool value) {
    GameEngine().isTestSimimulationOn = value;
  }

  LatLng? _lastRealGpsPosition = null;

  bool _isSidePanelVisible = false; //fixme

  void _centerMapOnCurrentLocation() {
    _mapController.move(_playerPosition, 16.0);
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
        _playerPosition = LatLng(position.latitude, position.longitude);
        //print("setting location to ${_location}");
        _processNewLocation(_playerPosition);
      }
      _locationServiceInitialized = true;
      _checkIfInitializationCompleted();
    });
  }

  void _processNewLocation(LatLng location) {
    for (final npc in _npcs) {
      npc.updatePlayerPosition(_playerPosition);
    }
    for (final hotspot in _hotspots) {
      if (hotspot.contains(_playerPosition)) {
        GameEngine().registerHotspot(hotspot);
      }
    }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlushBarService().setContext(context);
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

  FloatingActionButton buildFloatingActionButton() {
    return (FloatingActionButton(
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
    ));
  }

  List<ItemButton> buildItems() {
    return _items.where((i) => i.isOwned).map((item) {
      /*
      return IconButton(
        icon: Image.asset(
          'assets/story/${item.iconAsset}',
          width: 24,
          height: 24,
        ),
        onPressed: () async {
          await item.execute(context);
        },
      );
*/
      return ItemButton(item: item);
    }).toList();
  }

  void _moveSimulatedLocation(double x, double y) {
    setState(() {
      _playerPosition = LatLng(
        _playerPosition.latitude + x,
        _playerPosition.longitude + y,
      );
    });
    _processNewLocation(_playerPosition);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
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
    final actionsByTrigger = GameEngine().getActionsGroupedByTrigger();
/*
    if (!_isSidePanelVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (GameEngine().hasNewItems()) {
          await Future.delayed(Duration(seconds: 3));
          if (mounted) {
            setState(() {
              _isSidePanelVisible = true;
            });
          }
        }
      });
    }
*/
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: "Test Actions",
            onPressed: () {
              setState(() {
                showActionTestingPanel = !showActionTestingPanel;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.sports_esports_outlined),
            tooltip: "Simulate",
            onPressed: () {
              setState(() {
                if (!_isSimulatingLocation) {
                  _lastRealGpsPosition = _playerPosition;
                } else {
                  if (_lastRealGpsPosition != null) {
                    _playerPosition = _lastRealGpsPosition!;
                    _processNewLocation(_playerPosition);
                  }
                }
                _isSimulatingLocation = !_isSimulatingLocation;
              });
            },
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.menu_open),
                  tooltip: "Seitenleiste öffnen",
                  onPressed: () {
                    setState(() {
                      _isSidePanelVisible = !_isSidePanelVisible;
                      //GameEngine().markAllItemsAsSeen();
                    });
                  },
                ),
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
                  //buildFlutterMap(),
                  GameMapWidget(
                    location: _playerPosition,
                    mapController: _mapController,
                    currentHeading: _currentHeading,
                    currentMapRotation: _currentMapRotation,
                    isMapHeadingBasedOrientation: _isMapHeadingBasedOrientation,
                    isSimulatingLocation: _isSimulatingLocation,
                    onSimulatedLocationChange: (point) {
                      setState(() {
                        _playerPosition = point;
                        _processNewLocation(_playerPosition);
                      });
                    },
                    onNpcChatRequested: (npc) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            npc: npc,
                            onDispose: _checkForNewItemsWithDelay,
                          ),
                        ),
                      );
                    },
                  ),
                  buildMapOrientationModeButton(),
                  JoystickOverlay(
                    heading: _currentHeading,
                    onMove: (dx, dy) => _moveSimulatedLocation(dx, dy),
                    isVisible: _isSimulatingLocation,
                  ),
                  if (showActionTestingPanel)
                    ActionTestingPanel(
                      actionsByTrigger: actionsByTrigger,
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
                    children: buildItems(),
                  ),
                ],
              ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }


  void _checkForNewItemsWithDelay() async {
    print("👉 Check for new items triggered");

    // Prüfen, ob neue Items vorhanden sind
    if (!_isSidePanelVisible && GameEngine().hasNewItems()) {
      await Future.delayed(Duration(seconds: 10)); // Optional: sanfte Verzögerung
      if (!mounted) return;
      print("👉 New items found, opening side panel");
      setState(() {
        _isSidePanelVisible = true;
      });
      //GameEngine().markAllItemsAsSeen(); // Nicht vergessen: als "gesehen" markieren
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
