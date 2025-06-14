import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/services/log_service.dart';

class MovementUtils {
  static LatLng interpolatePosition(LatLng from, LatLng to, double distanceToTravel) {
    final totalDistance = Distance().as(LengthUnit.Meter, from, to);
    if (totalDistance == 0 || distanceToTravel >= totalDistance) return to;

    final fraction = distanceToTravel / totalDistance;
    final newLat = from.latitude + (to.latitude - from.latitude) * fraction;
    final newLng = from.longitude + (to.longitude - from.longitude) * fraction;
    return LatLng(newLat, newLng);
  }
}

enum MovementMode {
  idle,
  navigating,
  following,
  leading,
}

abstract class MovementController {
  LatLng get currentPosition;
  LatLng get targetPosition;
  LatLng updatePosition();
  void stopMoving();
  void teleportTo(LatLng toP);
  void teleportHome();
  void moveTo(LatLng toP);
}

class NPCMovementController implements MovementController {
  MovementMode mode = MovementMode.idle;
  LatLng currentBasePosition;
  LatLng toPosition;
  bool isMoving = false;
  DateTime movementStartTime = DateTime.now();
  double speedInKmh;

  List<LatLng> path;
  static const followingDistance = 10.0;

  static const double stopFollowingDistance = 10.0;
  static const double resumeFollowingDistance = 20.0;

  static const waitDistance = 50.0;
  static const continueDistance = 20.0;

  final VoidCallback onEnterRange;
  final VoidCallback onExitRange;
  LatLng Function()? getPlayerPosition;

  double get speedInms => (GameEngine().isGPSSimulating ? 150: speedInKmh * 1000 / 3600);

  NPCMovementController({
    required this.currentBasePosition,
    required this.toPosition,
    required this.speedInKmh,
    required this.onEnterRange,
    required this.onExitRange,
    required this.getPlayerPosition,
  }) : path = [];

  double get currentDistance {
    return Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  bool get isFollowing => mode == MovementMode.following;
  bool get isLeading => mode == MovementMode.leading;
  bool get isNavigating => mode == MovementMode.navigating;
  bool get isIdle => mode == MovementMode.idle;

  LatLng get playerPosition =>
      getPlayerPosition?.call() ?? SimMovementController.simHome;

  bool get isInCommunicationDistance =>
      currentDistance < GameEngine.conversationDistance;

  bool _wasInRange = false;

  void updatePlayerProximity() {
    final inRange = isInCommunicationDistance;

    if (inRange && !_wasInRange) {
      onEnterRange();
    } else if (!inRange && _wasInRange) {
      onExitRange();
    }
    _wasInRange = inRange;
  }

  double _getDistanceToTravelSince(DateTime startTime) {
    final now = DateTime.now();
    final timeDiffSeconds = now.difference(startTime).inMilliseconds / 1000.0;
    return adjustedSpeedInms * timeDiffSeconds;
  }

  @override
  LatLng get currentPosition => currentBasePosition;

  @override
  LatLng get targetPosition => toPosition;

  void maybeStartFollowing() {
    if (isFollowing && !isMoving && currentDistance > resumeFollowingDistance) {
      toPosition = playerPosition;
      movementStartTime = DateTime.now();
      isMoving = true;
    }
  }

  void maybeResumeLeading() {
    if (isLeading && !isMoving && currentDistance < continueDistance) {
      movementStartTime = DateTime.now();
      isMoving = true;
    }
  }


  static const double boostActivationThresholdSec = 10.0; // Boost aktivieren, wenn länger als 10s
  static const double boostDeactivationThresholdSec = 3.0; // Boost deaktivieren, wenn weniger als 3s
  static const double desiredBoostDurationSec = 5.0; // Ziel: in 5s aufholen

  /// Berechnet die aktuelle Geschwindigkeit des NPCs in m/s,
  /// basierend auf dem Abstand zum Spieler und dem gewünschten Verhalten.
  /// Boost wird aktiviert, wenn der NPC >10s brauchen würde,
  /// und deaktiviert, wenn er wieder <3s brauchen würde.
  @visibleForTesting
  double get adjustedSpeedInms {
    if (!isFollowing) return speedInms;

    final dist = currentDistance;
    final timeNeeded = dist / speedInms;

    // Boost aktivieren
    if (timeNeeded > boostActivationThresholdSec) {
      final boosted = dist / desiredBoostDurationSec;
      return boosted;
    }

    // Boost deaktivieren
    if (timeNeeded < boostDeactivationThresholdSec) {
      return speedInms;
    }

    // Normale Geschwindigkeit beibehalten
    return speedInms;
  }


  @override
  LatLng updatePosition() {
    if (!isMoving) {
      maybeStartFollowing();
      maybeResumeLeading();
      return currentBasePosition;
    }

    if (isFollowing) {
      toPosition = playerPosition;
    }

    final now = DateTime.now();
    var distanceToTravel = _getDistanceToTravelSince(movementStartTime);

    while (true) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        currentBasePosition,
        toPosition,
      );

      if (distanceToTravel < distance) {
        final interpolated = MovementUtils.interpolatePosition(
          currentBasePosition,
          toPosition,
          distanceToTravel,
        );

        final distanceToPlayer = Distance().as(
          LengthUnit.Meter,
          interpolated,
          playerPosition,
        );
        if (isFollowing && distanceToPlayer < stopFollowingDistance) {
          isMoving = false;
          currentBasePosition = interpolated;
          updatePlayerProximity();
          return interpolated;
        }
        if (isLeading && distanceToPlayer > waitDistance) {
          isMoving = false;
          currentBasePosition = interpolated;
          updatePlayerProximity();
          return interpolated;
        }

        // Normale Fortbewegung
        currentBasePosition = interpolated;
        movementStartTime = now;
        updatePlayerProximity();
        return interpolated;
      }
      // Ziel erreicht, gehe zum nächsten Wegpunkt
      currentBasePosition = toPosition;
      distanceToTravel -= distance;

      if (path.isNotEmpty) {
        toPosition = path.removeAt(0);
        final restMillis = (1000 * distanceToTravel / speedInms).round();
        movementStartTime = now.subtract(Duration(milliseconds: restMillis));
      } else {
        isMoving = false;
        updatePlayerProximity();
        return currentBasePosition;
      }
    }
  }

  @override
  void moveTo(LatLng toP) {
    path = [];
    mode = MovementMode.navigating;

    if (isMoving) {
      currentBasePosition = currentPosition;
    }

    toPosition = toP;
    isMoving = true;
    movementStartTime = DateTime.now();
  }

  void moveAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    toPosition = path.removeAt(0);
    isMoving = true;
    mode = MovementMode.navigating;
    movementStartTime = DateTime.now();
  }

  void leadAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    toPosition = path.removeAt(0);
    isMoving = true;
    mode = MovementMode.leading;
    movementStartTime = DateTime.now();
  }

  void startFollowing() {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    toPosition = playerPosition;
    path = [];
    isMoving = true;
    mode = MovementMode.following;
    movementStartTime = DateTime.now();
  }

  void leadTo(LatLng toP) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    toPosition = toP;
    path = [];
    mode = MovementMode.leading;
    movementStartTime = DateTime.now();

    // Prüfen ob er gleich starten darf
    final distanceToPlayer = Distance().as(
      LengthUnit.Meter,
      currentBasePosition,
      playerPosition,
    );
    isMoving = distanceToPlayer < waitDistance;
  }

  @override
  void stopMoving() {
    currentBasePosition = currentPosition;
    isMoving = false;
    mode = MovementMode.idle;
    path = [];
  }

  void spawn(double distance) {
    final random = Random();

    // Zufälliger Winkel (0–360 Grad in Radiant)
    final angle = random.nextDouble() * 2 * pi;

    // Umrechnung Meter → Grad
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng =
        metersPerDegreeLat * cos(playerPosition.latitude * pi / 180);

    final deltaLat = (distance * cos(angle)) / metersPerDegreeLat;
    final deltaLng = (distance * sin(angle)) / metersPerDegreeLng;

    currentBasePosition = LatLng(
      playerPosition.latitude + deltaLat,
      playerPosition.longitude + deltaLng,
    );
    isMoving = false;
    mode = MovementMode.idle;
  }

  @override
  void teleportHome() {
    LogService.w("⚠️ Teleportation not supported for NPCs");
    assert(false, "⚠️ Teleportation not supported for NPCs");
  }

  @override
  void teleportTo(LatLng newPosition) {
    LogService.w("⚠️ Teleportation not supported for NPCs");
    assert(false, "⚠️ Teleportation not supported for NPCs");
  }
}

class SimMovementController  implements MovementController {
  static const durationInSeconds = 5.0;
  static const simHome = LatLng(48.09048048682252, 16.296859109639993);
  LatLng currentBasePosition;
  LatLng toPosition;
  bool isMoving = false;
  DateTime movementStartTime = DateTime.now();

  SimMovementController({required LatLng startPosition})
      : currentBasePosition = startPosition,
        toPosition = startPosition,
        isMoving = false,
        movementStartTime = DateTime.now();

  double get speedInms {
    final totalDistance = Distance().as(
      LengthUnit.Meter,
      _movementStartPosition,
      toPosition,
    );
    return totalDistance / durationInSeconds;
  }

  @override
  void stopMoving() {
    currentBasePosition = currentPosition;
    toPosition = currentPosition;
    isMoving = false;
  }


  @override
  LatLng get currentPosition => currentBasePosition;

  @override
  LatLng get targetPosition => toPosition;

  late LatLng _movementStartPosition;

  @override
  void teleportHome() {
    teleportTo(simHome);
  }

  @override
  void teleportTo(LatLng newPosition) {
    currentBasePosition = newPosition;
    toPosition = newPosition;
    isMoving = false;
  }

  @override
  void moveTo(LatLng toP) {
    _movementStartPosition = currentBasePosition;

    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    final distance = Distance().as(LengthUnit.Meter, currentBasePosition, toP);
    if (distance == 0) {
      // Kein Ziel gesetzt
      return;
    }

    //speedInms = distance / durationInSeconds;
    toPosition = toP;
    movementStartTime = DateTime.now();
    isMoving = true;
  }

  @override
  LatLng updatePosition() {
    if (!isMoving) return currentBasePosition;

    final now = DateTime.now();
    final timeElapsed =
        now.difference(movementStartTime).inMilliseconds / 1000.0;
    final totalDistance = Distance().as(
      LengthUnit.Meter,
      _movementStartPosition,
      toPosition,
    );
    final distanceToTravel = speedInms * timeElapsed;

    if (distanceToTravel >= totalDistance) {
      currentBasePosition = toPosition;
      isMoving = false;
      return toPosition;
    }

    final interpolated = MovementUtils.interpolatePosition(
      _movementStartPosition,
      toPosition,
      distanceToTravel,
    );
    currentBasePosition = interpolated;
    return interpolated;
  }
}


class GpsMovementController implements MovementController {
  LatLng _lastGpsPosition;
  DateTime _lastGpsTimestamp;

  LatLng? _nextGpsPosition;
  DateTime? _nextGpsTimestamp;

  bool _isMoving = false;
  LatLng _currentInterpolatedPosition;

  @override
  LatLng get targetPosition => (_nextGpsPosition == null) ? _lastGpsPosition : _nextGpsPosition!;

  GpsMovementController(LatLng initialPosition)
      : _lastGpsPosition = initialPosition,
        _lastGpsTimestamp = DateTime.now(),
        _currentInterpolatedPosition = initialPosition;

  bool _hasReceivedFirstUpdate = false;
  final SpeedAverager _speedAverager = SpeedAverager(maxSamples: 5);

  void receiveGpsUpdate(LatLng newPosition) {
    LogService.d("📡 GPS Update erhalten: $newPosition");
    final now = DateTime.now();

    _speedAverager.addPosition(newPosition);

    // Fall 1: erster GPS-Punkt
    if (!_hasReceivedFirstUpdate) {
      _lastGpsPosition = newPosition;
      _currentInterpolatedPosition = newPosition;
      _lastGpsTimestamp = now;
      _isMoving = false;
      _hasReceivedFirstUpdate = true;
      return;
    }

    final speed = _speedAverager.averageSpeed;

    // Fall 2: keine Bewegung – direkt setzen
    if (speed <= 0.5) {
      _lastGpsPosition = newPosition;
      _currentInterpolatedPosition = newPosition;
      _lastGpsTimestamp = now;
      _isMoving = false;
      return;
    }

    // Neue Interpolation starten
    final dist = Distance().as(LengthUnit.Meter, _currentInterpolatedPosition, newPosition);

    // Interpolationsdauer basierend auf Geschwindigkeit berechnen (in ms)
    final estimatedMs = (1000 * dist / speed).round();

    // Dauer begrenzen, z.B. 250–2000 ms
    final clampedMs = estimatedMs.clamp(250, 2000);
    final duration = Duration(milliseconds: clampedMs);

    _lastGpsPosition = _currentInterpolatedPosition;
    _lastGpsTimestamp = now;
    _nextGpsPosition = newPosition;
    _nextGpsTimestamp = now.add(duration);
    _isMoving = true;
  }

  @override
  LatLng get currentPosition => _currentInterpolatedPosition;

  @override
  LatLng updatePosition() {
    if (!_isMoving || _nextGpsPosition == null || _nextGpsTimestamp == null) {
      return _currentInterpolatedPosition;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastGpsTimestamp).inMilliseconds;
    final total = _nextGpsTimestamp!.difference(_lastGpsTimestamp).inMilliseconds;

    if (total <= 0 || elapsed >= total) {
      _finalizeMovement(); // springt auf Ziel
      return _currentInterpolatedPosition;
    }

    final t = elapsed / total;

    _currentInterpolatedPosition = _interpolateFractional(
      _lastGpsPosition,
      _nextGpsPosition!,
      t,
    );

    return _currentInterpolatedPosition;
  }

  void _finalizeMovement() {
    _currentInterpolatedPosition = _nextGpsPosition!;
    _lastGpsPosition = _currentInterpolatedPosition;
    _lastGpsTimestamp = DateTime.now();
    _isMoving = false;
    _nextGpsPosition = null;
    _nextGpsTimestamp = null;
  }

  @override
  void stopMoving() {
    _isMoving = false;
    _nextGpsPosition = null;
    _nextGpsTimestamp = null;
  }

  LatLng _interpolateFractional(LatLng from, LatLng to, double t) {
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    return LatLng(lat, lng);
  }

  @override
  void teleportHome() {
    LogService.w("⚠️ Teleportation not supported while using GPS");
    assert(false, "⚠️ Teleportation not supported while using GPS");
  }

  @override
  void teleportTo(LatLng newPosition) {
    LogService.w("⚠️ Teleportation not supported while using GPS");
    assert(false, "⚠️ Teleportation not supported while using GPS");
  }

  @override
  void moveTo(LatLng toP) {
    LogService.w("⚠️ moveTo not supported while using GPS");
    assert(false, "⚠️ moveTo not supported while using GPS");
  }
}

class MovementSample {
  final LatLng position;
  final DateTime timestamp;

  MovementSample(this.position, this.timestamp);
}

class SpeedAverager {
  final int maxSamples;
  final Queue<MovementSample> _samples = Queue<MovementSample>();
  final Distance _distance = const Distance();

  SpeedAverager({this.maxSamples = 5});

  /// Fügt eine neue Position mit aktuellem Zeitstempel hinzu
  void addPosition(LatLng position) {
    final sample = MovementSample(position, DateTime.now());
    _samples.addLast(sample);
    if (_samples.length > maxSamples) {
      _samples.removeFirst();
    }
  }

  /// Durchschnittliche Geschwindigkeit in Meter/Sekunde
  double get averageSpeed {
    if (_samples.length < 2) return 0;

    double totalDistance = 0;
    double totalTime = 0;

    final samplesList = _samples.toList();
    for (int i = 1; i < samplesList.length; i++) {
      final prev = samplesList[i - 1];
      final current = samplesList[i];

      final d = _distance(prev.position, current.position); // in Meter
      final t = current.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;

      if (t > 0) {
        totalDistance += d;
        totalTime += t;
      }
    }

    return totalTime > 0 ? totalDistance / totalTime : 0;
  }

  /// Gibt die letzte bekannte Position zurück
  LatLng? get latestPosition => _samples.isNotEmpty ? _samples.last.position : null;

  /// Gibt die aktuelle Stichprobenanzahl zurück
  int get sampleCount => _samples.length;
}