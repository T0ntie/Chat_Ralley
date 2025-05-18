import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/engine/moving_behavior.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('NPCMovementController', () {
    late NPCMovementController behavior;
    final start = LatLng(51.5074, -0.1278); // London
    final end = LatLng(51.5101, -0.1278); // ≈ 300 m nördlich

    setUp(() {
      behavior = NPCMovementController(
        currentBasePosition: start,
        toPosition: end,
        speedInKmh: 3.6, // 1 m/s
      );
    });

    test('initial position is currentBasePosition', () {
      expect(
        behavior.currentPosition.latitude,
        closeTo(start.latitude, 0.00001),
      );
      expect(
        behavior.currentPosition.longitude,
        closeTo(start.longitude, 0.00001),
      );
    });

    test('moves toward target over time', () {
      behavior.moveTo(end);
      behavior.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 10),
      );

      final pos = behavior.updatePosition();

      // Sollte sich merklich in Richtung Ziel bewegt haben, aber noch nicht angekommen sein
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
      expect(behavior.isMoving, isTrue);
    });

    test('reaches target after enough time', () {
      behavior.moveTo(end);
      behavior.movementStartTime = DateTime.now().subtract(
        Duration(minutes: 10),
      );

      final pos = behavior.updatePosition();

      expect(pos.latitude, closeTo(end.latitude, 0.00001));
      expect(pos.longitude, closeTo(end.longitude, 0.00001));
      expect(behavior.isMoving, isFalse);
    });

    test('moveTo disables following and leading mode', () {
      behavior.isFollowing = true;
      behavior.isLeading = true;

      behavior.moveTo(end);

      expect(behavior.isFollowing, isFalse);
      expect(behavior.isLeading, isFalse);
      expect(behavior.isMoving, isTrue);
      expect(behavior.toPosition, end);
    });

    test('moveTo does not overwrite toPosition with playerPosition if was following before', () {
      behavior.startFollowing();
      behavior.playerPosition = LatLng(51.5000, -0.1278); // weiter weg
      final customTarget = end;

      behavior.moveTo(customTarget);
      behavior.movementStartTime = DateTime.now().subtract(Duration(seconds: 2));

      final pos = behavior.updatePosition();

      // NPC sollte sich in Richtung `end` bewegen, nicht zum Spieler
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(customTarget.latitude));
      expect(behavior.toPosition, customTarget);
      expect(behavior.isFollowing, isFalse);
    });

    test('stops following when close to player', () {
      behavior.startFollowing();
      behavior.playerPosition = end;
      behavior.currentBasePosition = end;
      behavior.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 1),
      );

      // simulate movement update
      final pos = behavior.updatePosition();

      expect(behavior.isMoving, isFalse);
      expect(pos.latitude, closeTo(end.latitude, 0.00001));
    });

    test('leads and waits if player is too far behind', () {
      behavior.leadTo(end);
      behavior.playerPosition = start;
      behavior.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 80),
      );

      final pos = behavior.updatePosition();

      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
      expect(behavior.isMoving, isFalse);
    });
  });

  group('PlayerMovementController', () {
    late PlayerMovementController controller;
    final start = LatLng(51.5074, -0.1278); // London
    final end = LatLng(51.5101, -0.1278); // ≈ 300 m nördlich

    setUp(() {
      controller = PlayerMovementController(startPosition: start);
    });

    test('initial position is startPosition', () {
      expect(
        controller.currentPosition.latitude,
        closeTo(start.latitude, 0.00001),
      );
      expect(
        controller.currentPosition.longitude,
        closeTo(start.longitude, 0.00001),
      );
    });

    test('teleportTo changes position instantly', () {
      controller.teleportTo(end);
      expect(
        controller.currentPosition.latitude,
        closeTo(end.latitude, 0.00001),
      );
      expect(
        controller.currentPosition.longitude,
        closeTo(end.longitude, 0.00001),
      );
      expect(controller.isMoving, isFalse);
    });

    test('moveTo sets correct speed and begins movement', () {
      controller.moveTo(end);
      expect(controller.isMoving, isTrue);
      expect(controller.toPosition, end);
      expect(controller.speedInms, greaterThan(0));
    });

    test('updatePosition moves player over time', () {
      controller.moveTo(end);
      controller.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 2),
      );

      final pos = controller.updatePosition();

      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
      expect(controller.isMoving, isTrue);
    });

    test('updatePosition stops when destination reached', () {
      controller.moveTo(end);
      controller.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 10),
      ); // Vollständige Dauer

      final pos = controller.updatePosition();

      expect(pos.latitude, closeTo(end.latitude, 0.00001));
      expect(pos.longitude, closeTo(end.longitude, 0.00001));
      expect(controller.isMoving, isFalse);
    });

    test('calling moveTo while moving restarts from current position', () {
      controller.moveTo(end);
      controller.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 2),
      );
      final midPoint = controller.updatePosition();

      final newTarget = LatLng(51.5110, -0.1278); // noch weiter nördlich
      controller.moveTo(newTarget);

      expect(
        controller.currentBasePosition.latitude,
        closeTo(midPoint.latitude, 0.00001),
      );
      expect(controller.toPosition, newTarget);
      expect(controller.isMoving, isTrue);
    });
  });

  group('NPCMovementController Path Navigation', () {
    late NPCMovementController npc;
    final start = LatLng(51.5074, -0.1278); // London
    final wp1 = LatLng(51.5078, -0.1278); // ≈ 44m nördlich
    final wp2 = LatLng(51.5082, -0.1278); // ≈ 44m nördlich
    final wp3 = LatLng(51.5086, -0.1278); // ≈ 44m nördlich
    final end = wp3;

    setUp(() {
      npc = NPCMovementController(
        currentBasePosition: start,
        toPosition: start,
        speedInKmh: 3.6, // 1 m/s
      );
    });

    test('moveAlong sets path and starts movement', () {
      npc.moveAlong([wp1, wp2, wp3]);

      expect(npc.isMoving, isTrue);
      expect(npc.toPosition, wp1);
      expect(npc.path.length, 2); // wp2, wp3 noch übrig
    });

    test('updatePosition progresses through multiple waypoints', () {
      npc.moveAlong([wp1, wp2, wp3]);

      // Simuliere sehr lange vergangene Zeit
      npc.movementStartTime = DateTime.now().subtract(Duration(seconds: 300));

      // Wiederholt Bewegung durchführen bis fertig
      while (npc.isMoving) {
        npc.updatePosition();
      }

      final pos = npc.currentPosition;

      expect(pos.latitude, closeTo(end.latitude, 0.0001));
      expect(pos.longitude, closeTo(end.longitude, 0.0001));
      expect(npc.path.isEmpty, isTrue);
      expect(npc.isMoving, isFalse);
    });

    test('leadAlong behaves like moveAlong and sets isLeading', () {
      npc.leadAlong([wp1, wp2]);

      expect(npc.isMoving, isTrue);
      expect(npc.isLeading, isTrue);
      expect(npc.isFollowing, isFalse);
      expect(npc.toPosition, wp1);
      expect(npc.path.length, 1); // wp2
    });

    test('stops when player is too far behind while leading', () {
      npc.leadAlong([wp1, wp2, wp3]);
      npc.playerPosition = start;

      npc.movementStartTime = DateTime.now().subtract(Duration(seconds: 80));

      // Bewegung fortsetzen, bis NPC stehen bleibt
      while (npc.isMoving) {
        npc.updatePosition();
      }

      final pos = npc.currentPosition;

      expect(npc.isMoving, isFalse);
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(wp3.latitude)); // nicht ganz angekommen
    });

  });


}
