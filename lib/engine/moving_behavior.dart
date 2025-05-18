import 'dart:math';
import 'dart:ui';

import 'package:hello_world/engine/game_engine.dart';
import 'package:latlong2/latlong.dart';

abstract class EntityMovementController {
  bool isMoving;
  DateTime movementStartTime;

  LatLng currentBasePosition;
  LatLng toPosition;
  double speedInKmh;
  double speedInms;

  EntityMovementController({
    required this.currentBasePosition,
    required this.toPosition,
    required this.speedInKmh,
  }) : isMoving = false,
       movementStartTime = DateTime.now(),
       speedInms = speedInKmh * 1000 / 3600;

  LatLng interpolatePosition(LatLng from, LatLng to, double distanceToTravel) {
    final totalDistance = Distance().as(LengthUnit.Meter, from, to);
    if (totalDistance == 0 || distanceToTravel >= totalDistance) return to;

    final fraction = distanceToTravel / totalDistance;
    final newLat = from.latitude + (to.latitude - from.latitude) * fraction;
    final newLng = from.longitude + (to.longitude - from.longitude) * fraction;
    return LatLng(newLat, newLng);
  }

  LatLng get currentPosition;

  moveTo(LatLng toP) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    toPosition = toP;
    isMoving = true;
    movementStartTime = DateTime.now();
  }

  void stopMoving() {
    currentBasePosition = currentPosition;
    isMoving = false;
  }
}

class NPCMovementController extends EntityMovementController {
  bool isFollowing;
  bool isLeading;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  List<LatLng> path;
  static const followingDistance = 5.0;
  static const waitDistance = 75.0;
  static const continueDistance = 20.0;

  final VoidCallback onEnterRange;
  final VoidCallback onExitRange;

  NPCMovementController({
    required super.currentBasePosition,
    required super.toPosition,
    required super.speedInKmh,
    required this.onEnterRange,
    required this.onExitRange,
  }) : isFollowing = false,
       isLeading = false,
       path = [];

  double get currentDistance {
    return Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  bool get isInCommunicationDistance =>
      currentDistance < GameEngine.conversationDistance;

  bool _wasInRange = false;

  void checkProximityToPlayer({
    required VoidCallback onEnterRange,
    required VoidCallback onExitRange,
  }) {
    final inRange = isInCommunicationDistance;

    if (inRange && !_wasInRange) {
      onEnterRange();
    } else if (!inRange && _wasInRange) {
      onExitRange();
    }

    _wasInRange = inRange;
  }

  _runProximityCheck() {
      checkProximityToPlayer(
        onEnterRange: onEnterRange,
        onExitRange: onExitRange,
      );
  }

  void checkForContinue() {
    if (isFollowing) {
      if (!isMoving && currentDistance > followingDistance) {
        movementStartTime = DateTime.now();
        toPosition = playerPosition;
        isMoving = true;
      }
    }
    if (isLeading) {
      if (!isMoving && currentDistance < continueDistance) {
        movementStartTime = DateTime.now();
        isMoving = true;
      }
    }
  }

  double _getDistanceToTravelSince(DateTime startTime) {
    final now = DateTime.now();
    final timeDiffSeconds = now.difference(startTime).inMilliseconds / 1000.0;
    return speedInms * timeDiffSeconds;
  }

  @override
  LatLng get currentPosition => currentBasePosition;

  LatLng updatePosition() {
    if (!isMoving) return currentBasePosition;

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
        final interpolated = interpolatePosition(
          currentBasePosition,
          toPosition,
          distanceToTravel,
        );

        final distanceToPlayer = Distance().as(
          LengthUnit.Meter,
          interpolated,
          playerPosition,
        );
        if (isFollowing && distanceToPlayer < followingDistance) {
          isMoving = false;
          currentBasePosition = interpolated;
          return interpolated;
        }
        if (isLeading && distanceToPlayer > waitDistance) {
          isMoving = false;
          currentBasePosition = interpolated;
          return interpolated;
        }

        // Normale Fortbewegung
        currentBasePosition = interpolated;
        movementStartTime = now;
        _runProximityCheck();
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
        _runProximityCheck();
        return currentBasePosition;
      }
    }
  }

  @override
  void moveTo(LatLng toP) {
    resetMovementModes();
    super.moveTo(toP);
  }

  void moveAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    toPosition = path.removeAt(0);
    isMoving = true;
    isFollowing = false;
    isLeading = false;
    movementStartTime = DateTime.now();
  }

  void leadAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    toPosition = path.removeAt(0);
    isMoving = true;
    isFollowing = false;
    isLeading = true;
    movementStartTime = DateTime.now();
  }

  void startFollowing() {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    toPosition = playerPosition;
    path = [];
    isFollowing = true;
    isMoving = true;
    isLeading = false;
    movementStartTime = DateTime.now();
  }

  void leadTo(LatLng toP) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    toPosition = toP;
    path = [];
    isFollowing = false;
    isLeading = true;
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
    isFollowing = false;
    isMoving = false;
    isLeading = false;
    path = [];
  }

  void resetMovementModes() {
    isFollowing = false;
    isLeading = false;
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
    isFollowing = false;
    isLeading = false;
  }

  void updatePlayerPosition(LatLng pos) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    playerPosition = pos;
    checkForContinue();
  }
}

class PlayerMovementController extends EntityMovementController {
  static const durationInSeconds = 5.0;
  static const simHome = LatLng(48.09048048682252, 16.296859109639993);

  PlayerMovementController({required LatLng startPosition})
    : super(
        currentBasePosition: startPosition,
        toPosition: startPosition,
        speedInKmh: 0,
      );

  @override
  LatLng get currentPosition => currentBasePosition;

  late LatLng _movementStartPosition;

  void teleportHome() {
    teleportTo(simHome);
  }

  void teleportTo(LatLng newPosition) {
    currentBasePosition = newPosition;
    toPosition = newPosition;
    isMoving = false;
  }

  @override
  void moveTo(LatLng toP) {
    _movementStartPosition = currentBasePosition;

    //fixme brauchen wir das wirklich?
    if (isMoving) {
      currentBasePosition = currentPosition; // 👈 Das hast du bisher NICHT!
    }
    final distance = Distance().as(LengthUnit.Meter, currentBasePosition, toP);
    if (distance == 0) {
      // Kein Ziel gesetzt
      return;
    }

    speedInms = distance / durationInSeconds;
    toPosition = toP;
    movementStartTime = DateTime.now();
    isMoving = true;
  }

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

    final interpolated = interpolatePosition(
      _movementStartPosition,
      toPosition,
      distanceToTravel,
    );
    currentBasePosition = interpolated;
    return interpolated;
  }
}
