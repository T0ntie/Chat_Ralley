import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/app_resources.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/item.dart';
import 'package:storytrail/gui/chat/chat_page.dart';
import 'package:storytrail/gui/debuging_panel.dart';
import 'package:storytrail/gui/game_map_widget.dart';
import 'package:storytrail/gui/item_button.dart';
import 'package:storytrail/gui/notification_services.dart';
import 'package:storytrail/gui/open_qr_scan_dialog_intent.dart';
import 'package:storytrail/gui/side_panel.dart';
import 'package:storytrail/services/compass_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.title, required this.trailId, this.onFatalError,});

  final String title;
  final String trailId;
  final void Function(String error)? onFatalError;


  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  final _frameRate = Duration(milliseconds: 33);

  bool _gameInitialized = false;

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
    try {
      await GameEngine().loadSelectedTrail(widget.trailId);
    } catch(e) {
      widget.onFatalError?.call('❌ Laden des StoryTrails fehlgeschlagen.' );
      return;
    }
    _gameInitialized = true;
    _checkIfInitializationCompleted();
    SnackBarService.showSuccessSnackBar(context, "✔️ Alle Spieldaten geladen");
  }

  void _checkIfInitializationCompleted() {
    print(
        "checking Initializaion: $_gameInitialized $_initializationCompleted");
    if (_gameInitialized &&
        //_locationServiceInitialized &&
        !_initializationCompleted) {
      setState(() {
        _initializationCompleted = true;
      });
      GameEngine().registerInitialization();
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
    _compassSubscription =
        CompassService.getCompassDirection().listen((heading,) {
          DateTime currentTime = DateTime.now();
          if ((heading - _currentHeading).abs() >= 5 ||
              currentTime
                  .difference(_lastHeadingUpdateTime)
                  .inSeconds >= 1) {
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

  Future<void> _initializeGameUI() async {
    try {
      await Future.wait([
        _initializeCompassStream(),
      ]);
    } catch (e) {

      widget.onFatalError?.call('❌ Initialisierung des Kompass fehlgeschlagen.' );
      return;
    }

    try {
      _initializeMapController();
    } catch (e) {
      widget.onFatalError?.call('❌ Initialisierung der Karte fehlgeschlagen.' );
      return;
    }

    _initializeUpdateTimer();
  }

  @override
  void initState() {
    super.initState();
    _initializeGameUI();
    _initializeGame();
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

  List<ItemButton> buildItems() {
    return _items.where((i) => i.isOwned).map((item) {
      return ItemButton(item: item);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
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
                await GameEngine().loadSelectedTrail("tiba"); //fixme
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
