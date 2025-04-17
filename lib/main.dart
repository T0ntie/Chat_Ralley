import 'package:flutter/material.dart';
import 'location_service.dart';
import 'compass_service.dart';
import 'chat_page.dart';
import 'npc.dart';
import 'story_line.dart';
import 'resources.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env"); // lädt die .env-Datei
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Chat Ralleyfbuild'),
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
  final String title = "Chat Ralley";
  LatLng _location = LatLng(51.5074, -0.1278); // Beispiel für London
  bool _isLocationLoaded = false;
  bool _backendRessourcesLoaded = false;
  bool _initializationCompleted = false;

  double _currentHeading = 0.0;
  DateTime _lastHeadingUpdateTime = DateTime.now();
  final MapController _mapController = MapController();
  double _currentMapRotation = 0.0;
  late final StreamSubscription<MapEvent> _mapControllerSubscription;
  late final StreamSubscription<double> _compassSubscription;
  late final StreamSubscription<Position> _positionSubscription;
  late final StoryLine _storyLine;
  List<Npc> _nPCs = [];

  bool _isMapHeadingBasedOrientation = false;

  void _centerMapOnCurrentLocation() {
    _mapController.move(_location, 16.0);
  }

  void _switchMapOrientationMode() {
    _isMapHeadingBasedOrientation = !_isMapHeadingBasedOrientation;
    print(
      "switching map orientation to dyniamic orientation: " +
          _isMapHeadingBasedOrientation.toString(),
    );
    _mapController.rotate(_isMapHeadingBasedOrientation ? _currentHeading : 0);
    _currentMapRotation = 0;
  }

  Future<void> _loadBackendResources() async {
    try {
      _storyLine = await StoryLine.loadStoryLine();
      _nPCs = _storyLine.npcs;
      _backendRessourcesLoaded = true;
      _checkIfInitializationCompleted();
    } catch (e) {
      print('Exception occoured: ${e}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Story konnte nicht geladen werden")),
      );
    }
  }

  void _checkIfInitializationCompleted() {
    if (_backendRessourcesLoaded &&
        _isLocationLoaded &&
        !_initializationCompleted) {
      setState(() {
        _initializationCompleted = true;
      });
    }
  }

  Future<void> _initializeLocationStream() async {
    await LocationService.initialize(); // Warten bis der Stream bereit ist
    _positionSubscription = LocationService.getPositionStream().listen((
      Position position,
    ) {
      //print("now updating the position" + position.toString());

      // Verwende setState, um den Zustand zu ändern und die UI zu aktualisieren
      _location = LatLng(position.latitude, position.longitude);

      for (final npc in _nPCs) {
        npc.updatePlayerPosition(_location);
      }
      //print("all npcs should be updated");
      _isLocationLoaded = true;
      _checkIfInitializationCompleted();
    });
  }

  void initializeMapController() {
    _mapControllerSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate) {
        setState(() {
          // Aktualisiere den Rotationswinkel
          _currentMapRotation = event.camera.rotation;
        });
      }
    });
  }

  Future<void> _initializeCompassStream() async {
    CompassService.initialize();
    _compassSubscription = CompassService.getCompassDirection().listen((
      heading,
    ) {
      DateTime currentTime = DateTime.now();
      if ((heading - _currentHeading).abs() >= 5 ||
          currentTime.difference(_lastHeadingUpdateTime).inSeconds >= 1) {
        //print("now updating compass heading to " + heading.toString());
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

  @override
  void initState() {
    super.initState();
    _loadBackendResources();
    _initializeCompassStream();
    _initializeLocationStream();
    initializeMapController();
  }

  // Dialog anzeigen, wenn der Marker angetippt wird
  void _showNPCInfo(BuildContext context, Npc npc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('NPC Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${npc.displayName}'),
              Text(
                'Position:${npc.position.latitude.toStringAsFixed(3)}, ${npc.position.longitude.toStringAsFixed(3)}',
              ),
              Text(
                //'Distance: ${Distance().as(LengthUnit.Meter, _location, npc.position).toStringAsFixed(1)} meters',
                'Distance: ${npc.currentDistance} meters',
              ),
              SizedBox(height: 10),
              if (!npc.canCommunicate())
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Komm näher, um mit ${npc.displayName} zu kommunizieren.",
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            Tooltip(
              message:
                  "Du musst näher kommen, um mit ${npc.displayName} kommunizieren zu können.",
              child: TextButton(
                child: Text('Chat starten'),
                onPressed:
                    npc.canCommunicate()
                        ? () {
                          Navigator.of(
                            context,
                          ).pop(); // Erst den Dialog schließen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(npc: npc),
                            ),
                          );
                        }
                        : null,
              ),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
              },
            ),
          ],
        );
      },
    );
  }

  Marker buildLocationMarker() {
    return (Marker(
      point: _location,

      // Die Position des Markers ist der aktuelle Standort
      child: Transform.rotate(
        angle:
            (_isMapHeadingBasedOrientation ? _currentHeading : _currentHeading) *
            (pi / 180),
        child: Resources.playerPositionIcon(),
      ),
    ));
  }

  List<Marker> buildNPCMarkers() {
    return _nPCs.map((npc) {
      return Marker(
        point: npc.position, // Verwende die Position des NPCs
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
                child: Resources.getNPCIcon(npc.icon),
              ),
              if (npc.canCommunicate())
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
                    child: Resources.getChatBubbleIcon(),
                  ),
                ),
              Positioned(
                bottom: 15, // Position unter dem Marker
                child: Text(
                  npc.displayName, // Der Name des NPCs
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black,
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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _location, initialZoom: 16.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(markers: [buildLocationMarker(), ...buildNPCMarkers()]),
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
        child:  Resources.getMapHeadingIcon(_isMapHeadingBasedOrientation),
      ),
    ));
  }

  FloatingActionButton buildFloatingActionButton() {
    return (FloatingActionButton(
      heroTag: "CenterLocation_fab",
      onPressed: () {
        setState(() {
          // Wenn der Button gedrückt wird, zentrieren wir die Karte auf den aktuellen Standort
          _centerMapOnCurrentLocation();
        });
      },
      child: Resources.centerLocationIcon(),// Zeigt ein Symbol für den "Mein Standort"-Button
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            tooltip: "Chat",
            onPressed: () {
              //print("chat pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(npc: _nPCs[0]),
                ),
              );
            },
          ),
        ],
      ),
      body:
          !_isLocationLoaded
              ? Center(
                child: CircularProgressIndicator(),
              ) // Ladeanzeige, wenn der Standort noch nicht verfügbar ist
              : Stack(
                children: [buildFlutterMap(), buildMapOrientationModeButton()],
              ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  @override
  void dispose() {
    _mapControllerSubscription.cancel();
    _compassSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }
}
