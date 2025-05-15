import 'dart:math';

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

class NPCMovementController extends EntityMovementController{
  bool isFollowing;
  bool isLeading;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  List<LatLng> path;
  static const followingDistance = 5.0;
  static const waitDistance = 75.0;
  static const continueDistance = 20.0;

  NPCMovementController({
    required super.currentBasePosition,
    required super.toPosition,
    required super.speedInKmh,
  }) :  isFollowing = false,
        isLeading = false,
        path = [];

  double get currentDistance {
    return Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  void checkForContinue()
  {
    if (isFollowing) {
      if (currentDistance > followingDistance) {
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

  void checkForStopOrWait()
  {
    if (!isMoving) return;

    final now = DateTime.now();
    final timeDiffSeconds =
        now.difference(movementStartTime).inMilliseconds / 1000.0;
    var distanceToTravel = speedInms * timeDiffSeconds;

    while (true) { //alle punkte im Pfad abarbeiten
      final distance = const Distance().as(
        LengthUnit.Meter,
        currentBasePosition,
        toPosition,
      );

      //Fall 1: noch nicht am Ziel
      if (distanceToTravel < distance) {

        final interpolatedPosition = interpolatePosition(
          currentBasePosition,
          toPosition,
          distanceToTravel,
        );

        final distanceToPlayer = const Distance().as(
          LengthUnit.Meter,
          interpolatedPosition,
          playerPosition,
        );

        if (isFollowing) {
          //zu nah am Spieler "aufgelaufen" vorerst stop (warten)
          if (distanceToPlayer < followingDistance) {
            isMoving = false;
            currentBasePosition = interpolatedPosition;
            return;
          }
        }

        if (isLeading) {
          //Spieler zu weit "zurückgefalle" vorerst stop (warten)
          if (distanceToPlayer > waitDistance) {
            isMoving = false;
            currentBasePosition = interpolatedPosition;
            return;
          }
        }
        currentBasePosition = interpolatedPosition;
        movementStartTime = now;
        return;
      }

      //Fall 2: Ziel erreicht
      currentBasePosition = toPosition;
      distanceToTravel -= distance;

      if (path.isNotEmpty) {
        toPosition = path.removeAt(0);
        //  restliche Zeit verwerten
        final restMillis = (1000 * distanceToTravel / speedInms).round();
        movementStartTime = now.subtract(Duration(
          milliseconds: restMillis));
      }
      else {
        isMoving = false;
        return;
      }
    }
  }

  double _getDistanceToTravelSince(DateTime startTime) {
    final now = DateTime.now();
    final timeDiffSeconds = now.difference(startTime).inMilliseconds / 1000.0;
    return speedInms * timeDiffSeconds;
  }

  LatLng get currentPosition {
    if (!isMoving) return currentBasePosition;

    var distanceToTravel = _getDistanceToTravelSince(movementStartTime);
    final distance = const Distance().as(
      LengthUnit.Meter,
      currentBasePosition,
      toPosition,
    );

    checkForStopOrWait();

    if (!isMoving) return currentBasePosition;

    distanceToTravel = _getDistanceToTravelSince(movementStartTime);

    final interpolatedPosition = interpolatePosition(
      currentBasePosition,
      toPosition,
      distanceToTravel,
    );

    return interpolatedPosition;
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
    final distanceToPlayer = Distance().as(LengthUnit.Meter, currentBasePosition, playerPosition);
    isMoving = distanceToPlayer < waitDistance;
  }

  void stopMoving() {
    currentBasePosition = currentPosition;
    isFollowing = false;
    isMoving = false;
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