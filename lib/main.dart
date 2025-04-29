import 'package:flutter/material.dart';
import 'package:hello_world/gui/notification_services.dart';
import 'dart:math';
import 'package:hello_world/gui/npc_info_dialog.dart';
import 'services/location_service.dart';
import 'services/compass_service.dart';
import 'gui/chat_page.dart';
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
import 'package:flutter_joystick/flutter_joystick.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ResourceColors.seed,)
      ),
      home: const MyHomePage(title: 'Chat Ralley'),
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
  final String title = "Chat Ralley";
  LatLng _location = LatLng(51.5074, -0.1278); // Beispiel für London
  bool _isLocationLoaded = false;
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

  List<Hotspot> get _hotspots => GameEngine().hotspots;
  late final Timer _updateTimer;

  bool _isMapHeadingBasedOrientation = false;

  bool get _isGPSSimulating => GameEngine().isTestSimimulationOn;
  set _isGPSSimulating(bool value) {
    GameEngine().isTestSimimulationOn = value;
  }

  LatLng? _realPosition = null;

  void _centerMapOnCurrentLocation() {
    _mapController.move(_location, 16.0);
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
    if (_gameInitialized && _isLocationLoaded && !_initializationCompleted) {
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
      if (!_isGPSSimulating) {
        _location = LatLng(position.latitude, position.longitude);
        print("setting location to ${_location}");
        _processNewLocation(_location);
      }
      _isLocationLoaded = true;
      _checkIfInitializationCompleted();
    });
  }

  void _processNewLocation(LatLng location) {
      for (final npc in _npcs) {
        npc.updatePlayerPosition(_location);
      }
      for (final hotspot in _hotspots) {
        if (hotspot.contains(_location)) {
          GameEngine().registerHotspot(hotspot);
        }
      }
  }

  void _initializeMapController() {
    _mapControllerSubscription = _mapController.mapEventStream.listen((
      event,
    ) {
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

    try{
      print (" Bevor Initialize Game");
      await _initializeGame();
      print (" danach Initialize Game");
    }
    catch(e) {
      print (" im catch Initialize Game");
      _initializationError = '❌ Initialisierung der Spieldaten fehlgeschlagen.';
      SnackBarService.showErrorSnackBar(context, _initializationError!);
      return;
    }

    try {
      print (" Bevor Wait");
      await Future.wait([
        _initializeCompassStream(),
        _initializeLocationStream(),
      ]);
      print (" Nach Wait");

    }
    catch (e) {
      print (" im zweiten Catch");
      _initializationError = '❌ Initialisieren der Standortbestimmung fehlgeschlagen.';
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
    FlushBarService().setContext(context);
    _initializeApp();
  }

  void _showNPCInfo(BuildContext context, Npc npc) {
    showDialog(
      context: context,
      builder: (BuildContext) {
        return NpcInfoDialog(npc: npc);
      },
    );
  }

  Marker buildLocationMarker() {
    return (Marker(
      point: _location,

      // Die Position des Markers ist der aktuelle Standort
      child: Transform.rotate(
        angle:
            (_isMapHeadingBasedOrientation
                ? _currentHeading
                : _currentHeading) *
            (pi / 180),
        child: AppIcons.playerPosition,
      ),
    ));
  }

  List<Marker> buildHotspotMarkers() {
    return _hotspots.where((hotspot) => hotspot.isVisible).map((hotspot) {
      return Marker(
        point: hotspot.position,
        width: 60, // feste Markerbreite
        height: 80, // genug Höhe für Icon + Text
        child: Transform.rotate(
          angle: (_isMapHeadingBasedOrientation
              ? _currentHeading
              : -_currentMapRotation) *
              (pi / 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  print("🎯 Tapped on Hotspot");
                },
                child: AppIcons.hotspot(context), // oder hotspot.icon
              ),
              const SizedBox(height: 4), // Abstand zwischen Icon und Text
              Text(
                hotspot.name,
                style: TextStyle(
                  fontSize: 11,
                  color: ResourceColors.npcName,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Marker> buildNPCMarkers() {
    return _npcs.where((npc) => npc.isVisible).map((npc) {
      return Marker(
        point: npc.currentPosition, // Verwende die Position des NPCs
        width: 170.0,
        height: 100.0,
        child: Transform.rotate(
          angle:
              (_isMapHeadingBasedOrientation
                  ? _currentHeading
                  : -_currentMapRotation) *
              (pi / 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _showNPCInfo(context, npc);
                },
                child: AppIcons.npc(context, npc.icon),
              ),
              if (npc.hasSomethingToSay /*.canCommunicate()*/ )
                Positioned(
                  top: 5,
                  right: 40, // Verschieben der Sprechblase nach oben
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(npc: npc),
                        ),
                      );
                    },
                    child: AppIcons.chatBubble(context),
                  ),
                ),
              Positioned(
                bottom: 15, // Position unter dem Marker
                child: Text(
                  npc.displayName, // Der Name des NPCs
                  style: TextStyle(
                    fontSize: 11,
                    color: ResourceColors.npcName,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(); // Umwandeln des iterierbaren Objekts (Map) in eine Liste
  }

  FlutterMap buildFlutterMap() {
    final pulse = _getPulseState(GameEngine.conversationDistance);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _location,
        initialZoom: 16.0,
        onLongPress: (tapPosition, point) {
          if (_isGPSSimulating)
            {
              setState(() {
                _location = point;
                _processNewLocation(_location);
              });
            }
        },
        onTap: (tapPosition, point) {
          print('Tapped on location: ${point.latitude}, ${point.longitude}');
        }
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        CircleLayer(
          circles: [
            if (_isGPSSimulating)..._hotspots
                .where((h) => h.isVisible)
                .map(
                  (hotspot) => CircleMarker(
                    point: hotspot.position,
                    radius: hotspot.radius,
                    useRadiusInMeter: true,
                    color: ResourceColors.hotspotCircle.withAlpha((0.1 * 255).toInt()),
                    borderColor: ResourceColors.hotspotCircle.withAlpha((0.5 * 255).toInt()),
                    borderStrokeWidth: 2,
                  ),
                ),
            CircleMarker(
              point: _location,
              radius: pulse.radius,
              useRadiusInMeter: true,
              color:
                  pulse.maxReached
                      ? Colors.transparent
                      : ResourceColors.playerPositionCircle .withAlpha(
                        (pulse.colorFade * 0.5 * 255).toInt(),
                      ),
              borderColor:
                  pulse.maxReached
                      ? ResourceColors.playerPositionFadeoutCircle.withAlpha(
                        ((pulse.colorFade + 0.2) * 255).toInt(),
                      )
                      : ResourceColors.playerPositionCircle.withAlpha(
                        (pulse.colorFade * 0.5 * 255).toInt(),
                      ),
              borderStrokeWidth: 2,
            ),

            // Ring exakt bei 100% Radius
            if (pulse.maxReached)
              CircleMarker(
                point: _location,
                radius: GameEngine.conversationDistance,
                // Fixer Wert = 100% Radius
                useRadiusInMeter: true,
                color: ResourceColors.playerPositionCircle.withAlpha(
                  (pulse.colorFade * 0.5 * 255).toInt(),
                ),
                borderColor: ResourceColors.playerPositionCircle.withAlpha(
                  (pulse.colorFade * 0.3 * 255).toInt(),
                ),
                borderStrokeWidth: 2,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            buildLocationMarker(),
            ...buildHotspotMarkers(),
            ...buildNPCMarkers(),
          ],
        ),
      ], // Children
    );
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
      child:
          AppIcons.centerLocation(context), // Zeigt ein Symbol für den "Mein Standort"-Button
    ));
  }

  Positioned buildJoystick() {
    return Positioned(
      bottom: 5,
      left: 5,
      child: Transform.scale(
        scale: 0.5, // oder 80, 60 – je nach Geschmack
        child: Joystick(
          mode: JoystickMode.all,
          stickOffsetCalculator: CircleStickOffsetCalculator(),
          listener: (details) {
            const double step = 0.00005; // Schrittweite pro Tick
            final double headingRadians = _currentHeading * (pi / 180);

            //in Nordausrichtung
            final double dx = -details.y;
            final double dy = details.x;

            //drehen in richtung heading
            final double drx =
                dx * cos(headingRadians) - dy * sin(headingRadians);
            final double dry =
                dx * sin(headingRadians) + dy * cos(headingRadians);

            _moveSimulatdLocation(drx * step, dry * step);
          },
        ),
      ),
    );
  }

  void _moveSimulatdLocation(double x, double y) {
    setState(() {
      _location = LatLng(_location.latitude + x, _location.longitude + y);
    });
    _processNewLocation(_location);
  }

  @override
  Widget build(BuildContext context) {

    if (_initializationError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcons.error(context), //Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                      _isLocationLoaded = false;
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
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.sports_esports_outlined),
            tooltip: "Simulate",
            onPressed: () {
              if (!_isGPSSimulating) {
                _realPosition = _location;
              } else {
                if (_realPosition != null) {
                  _location = _realPosition!;
                }
              }
              _isGPSSimulating = !_isGPSSimulating;
              print("simulationg: $_isGPSSimulating");
            },
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            tooltip: "Chat",
            onPressed: () {
              //print("chat pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(npc: _npcs[0]),
                ),
              );
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
                  buildFlutterMap(),
                  buildMapOrientationModeButton(),
                  if (_isGPSSimulating) buildJoystick(),
                ],
              ),
      floatingActionButton: buildFloatingActionButton(),
    );
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

class PulseState {
  final double radius;
  final bool maxReached;
  final double colorFade;

  PulseState({
    required this.radius,
    required this.maxReached,
    required this.colorFade,
  });
}

PulseState _getPulseState(double baseRadius) {
  const pulseDuration = 2000; // in ms
  const double maxFactor = 1.6;
  const double whiteRingStart = 1.0;

  final int now = DateTime.now().millisecondsSinceEpoch;
  final double t = (now % pulseDuration) / pulseDuration; // 0.0 - 1.0
  final double currentFactor = t * maxFactor;
  final double radius = baseRadius * currentFactor;
  final double colorFade = (1 - t).abs();

  final bool maxReached = currentFactor >= whiteRingStart;

  return PulseState(
    radius: radius,
    maxReached: maxReached,
    colorFade: colorFade,
  );
}
