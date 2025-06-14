import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:aitrailsgo/app_resources.dart';
import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/engine/item.dart';
import 'package:aitrailsgo/gui/camera_flight.dart';
import 'package:aitrailsgo/gui/chat/chat_page.dart';
import 'package:aitrailsgo/gui/debuging_panel.dart';
import 'package:aitrailsgo/gui/game_map_widget.dart';
import 'package:aitrailsgo/gui/items/item_button.dart';
import 'package:aitrailsgo/gui/notification_services.dart';
import 'package:aitrailsgo/gui/intents/open_qr_scan_dialog_intent.dart';
import 'package:aitrailsgo/gui/continue_game_dialog.dart';
import 'package:aitrailsgo/gui/side_panel.dart';
import 'package:aitrailsgo/gui/intents/ui_intent.dart';
import 'package:aitrailsgo/main.dart';
import 'package:aitrailsgo/services/compass_service.dart';
import 'package:aitrailsgo/services/firebase_serice.dart';
import 'package:aitrailsgo/services/log_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.title,
    required this.trailId,
    this.onFatalError,
  });

  final String title;
  final String trailId;
  final void Function(String error)? onFatalError;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen>
    with RouteAware, TickerProviderStateMixin {
  final _frameRate = Duration(milliseconds: 33);

  //bool _gameInitialized = false;
  bool _initializationCompleted = false;

  double _currentHeading = 0.0;
  DateTime _lastHeadingUpdateTime = DateTime.now();
  final MapController _mapController = MapController();

  MapController get mapController => _mapController;

  double _currentMapRotation = 0.0;
  late final StreamSubscription<MapEvent> _mapControllerSubscription;
  late final StreamSubscription<double> _compassSubscription;

  List<Item> get _items => GameEngine().items;

  late final Timer _updateTimer;

  bool _isMapHeadingBasedOrientation = false;

  bool get _isSimulatingLocation => GameEngine().isGPSSimulating;
  bool _debuggingVisible = false;

  bool showActionTestingPanel = false;

  set _isSimulatingLocation(bool value) {
    setState(() {
      GameEngine().setSimulationMode(value);
    });
  }

  LatLng? _lastRealGpsPosition;

  bool _isSidePanelVisible = false;
  bool _highlightScanButton = false;

  void _centerMapOnCurrentLocation() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(GameEngine().playerPosition, currentZoom);
  }

  void _switchMapOrientationMode() {
    _isMapHeadingBasedOrientation = !_isMapHeadingBasedOrientation;
    _mapController.rotate(_isMapHeadingBasedOrientation ? _currentHeading : 0);
    _currentMapRotation = 0;
  }

  Future<void> _initializeGame() async {
    try {
      await GameEngine().loadSelectedTrail(widget.trailId);
    } catch (e, stackTrace) {
      log.e(
        '❌ Failed to load selcted trail: ${widget.trailId}',
        error: e,
        stackTrace: stackTrace,
      );
      widget.onFatalError?.call('❌ Laden des Trails fehlgeschlagen.');
      return;
    }

    setState(() {
      _initializationCompleted = true;
    });

    // _checkIfInitializationCompleted();
    log.i('✅ Alle Spieldaten erfolgreich geladen');
    if (!mounted) return;
    SnackBarService.showSuccessSnackBar(context, "✔️ Alle Spieldaten geladen");
  }

  void _initializeMapController() {
    _mapControllerSubscription = _mapController.mapEventStream.listen((event) {
      /*
      if (event is MapEventMoveEnd) {
        print("Zoomlevel: ${_mapController.camera.zoom}");
      }
*/

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
    } catch (e, stackTrace) {
      log.e(
        '❌ Failed to initialize compass service.',
        error: e,
        stackTrace: stackTrace,
      );
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
        GameEngine().updatePlayerPosition();
        GameEngine().updateAllNpcPositions();
        setState(() {});
      }
    });
  }

  Future<void> _initializeGameUI() async {
    try {
      await _initializeCompassStream();
    } catch (e, stackTrace) {
      log.e(
        '❌ Failed to initialize compass stream',
        error: e,
        stackTrace: stackTrace,
      );
      widget.onFatalError?.call(
        '❌ Initialisierung des Kompass fehlgeschlagen.',
      );
      return;
    }

    try {
      _initializeMapController();
    } catch (e, stackTrace) {
      log.e(
        '❌ Failed to initialize map controller',
        error: e,
        stackTrace: stackTrace,
      );
      widget.onFatalError?.call('❌ Initialisierung der Karte fehlgeschlagen.');
      return;
    }
    _initializeUpdateTimer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null) {
        routeObserver.subscribe(this, route);
      }

      _initializeAll();
    });
  }

  void _initializeAll() async {
    await Future.wait([_initializeGameUI(), _initializeGame()]);
    _maybeLoadGameState();
  }

  Future<void> _handleDeferredGUIEvents() async {
    await GameEngine().flushDeferredActions(context);
    //checkForNewItemsWithDelay();
    UiIntentQueue().flush(this);
  }

  @override
  void didPopNext() {
    _handleDeferredGUIEvents();
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
                GameEngine().playerMovementController.teleportHome();
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
                _debuggingVisible = !_debuggingVisible;
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
                'assets/logo/aitrailsgo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Text(
          widget.title,
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
                  // von Echtbetrieb => Simulation
                  if (!_isSimulatingLocation) {
                    _lastRealGpsPosition = GameEngine().playerPosition;
                    // von Simulation => Echtbetrieb
                  } else {
                    GameEngine().playerMovementController.teleportTo(
                      _lastRealGpsPosition!,
                    );
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
                await GameEngine().loadSelectedTrail(
                  //fixme GameSate muss gelöscht werden
                  GameEngine().trailId!,
                ); //fixme testen
                final currentPosition = GameEngine().playerPosition;
                GameEngine().setRealGpsPositionAndNotify(currentPosition);
                GameEngine().registerInitialization();
              },
            ),
          if (_debuggingVisible)
            IconButton(
              icon: Icon(Icons.save),
              tooltip: "Spielstand speichern",
              onPressed: () async {
                saveGame();
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
                      actionsByNpc:
                          GameEngineDebugger.getActionsGroupedByNpc(),
                      flags: GameEngine().flags,
                      items: GameEngine().items,
                    ),
                  SidePanel(
                    isVisible: (_isSidePanelVisible),
                    highlightScanButton: _highlightScanButton,
                    onClose: () {
                      setState(() {
                        _isSidePanelVisible = false;
                        _highlightScanButton = false;
                        GameEngine().markAllItemsAsSeen();
                      });
                    },
                    onScan: () {
                      _highlightScanButton = false;
                      setState(() {
                        OpenScanDialogIntent(
                          title: "Fund erfassen",
                          expectedItems: GameEngine().getScannableItems(),
                        ).call(this);
                      });
                    },

                    children: buildItems(),
                  ),
                ],
              ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  void highlightScanButton() async {
    log.d("highlight the scan item button in sidepanel");
    if (!_isSidePanelVisible) {
      await Future.delayed(Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _isSidePanelVisible = true;
      });

      setState(() {
        _highlightScanButton = true;
      });
    }
  }

  void checkForNewItemsWithDelay() async {
    log.d("👉 Prüfe ob neue Items anzuzeigen sind....");

    // Prüfen, ob neue Items vorhanden sind
    if (!_isSidePanelVisible && GameEngine().hasNewItems()) {
      log.d("👉 .... ja neue Items vorhanden.");
      await Future.delayed(Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isSidePanelVisible = true;
      });
    } else {
      log.d("👉 .... nein keine neuen Items.");
    }
  }

  void _maybeLoadGameState() async {
    Map<String, dynamic>? gameState = await FirestoreService.loadGameState(
      widget.trailId,
    );

    if (gameState == null) {
      log.i("Kein Spielstand vorhanden.");
      GameEngine().registerInitialization();
      return;
    }

    Map<String, dynamic> meta = gameState['meta'];
    final DateTime savedTime = DateTime.parse(meta['saveTime']);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ContinueGameDialog(
            saveDate: savedTime,
            onLoadGame: () async {
              try {
                GameEngine().loadGameState(gameState);
              } catch (e, stackTrace) {
                log.e(
                  "❌ Failed to load game state",
                  error: e,
                  stackTrace: stackTrace,
                );
                rethrow;
              }
              log.i("✅ Spielstand erfolgreich gespeichert");
              SnackBarService.showSuccessSnackBar(
                context,
                "✔️ Spielstand erfolgreich wieder hergestellt",
              );
              GameEngine().registerRestore();
              await CameraFlight(
                state: this,
                controller: mapController,
                to: GameEngine().lastSaveLocation!,
              ).animate();
            },
            onNewGame: () {
              GameEngine().registerInitialization();
            },
          ),
    );
  }

  void saveGame() async {
    final Map<String, dynamic> saveData;
    try {
      saveData = GameEngine().saveGameState();
    } catch (e, stackTrace) {
      log.e("❌ Failed to create save state.", error: e, stackTrace: stackTrace);
      assert(false, "❌ Failed to create save state.");
      return;
    }
    try {
      FirestoreService.saveGameState(
        trailId: GameEngine().trailId!,
        jsonGameState: saveData,
      );
    } catch (e, stacktrace) {
      log.e("❌ Failed to save game state", error: e, stackTrace: stacktrace);
      assert(false, "❌ Failed to create save state.");
      return;
    }
    log.i("✅ Spielstand erfolgreich gespeichert");
    SnackBarService.showSuccessSnackBar(
      context,
      "✔️ Spielstand erfolgreich gespeichert.",
    );
  }

  @override
  void dispose() {
    _mapControllerSubscription.cancel();
    _compassSubscription.cancel();
    _updateTimer.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }
}
