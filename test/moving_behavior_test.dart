import 'package:flutter_test/flutter_test.dart';
import 'package:storytrail/engine/moving_controller.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('NPCMovementController', () {
    late NPCMovementController movementController;
    final start = LatLng(51.5074, -0.1278); // London
    final end = LatLng(51.5101, -0.1278); // ≈ 300 m nördlich

    setUp(() {
      movementController = NPCMovementController(
        currentBasePosition: start,
        toPosition: end,
        speedInKmh: 3.6,
        onExitRange: () => {},
        onEnterRange: () => {},
        getPlayerPosition: () => LatLng(51.5074, -0.1278),

      );
    });

    test('initial position is currentBasePosition', () {
      expect(
        movementController.currentPosition.latitude,
        closeTo(start.latitude, 0.00001),
      );
      expect(
        movementController.currentPosition.longitude,
        closeTo(start.longitude, 0.00001),
      );
    });

    test('moves toward target over time', () {
      movementController.moveTo(end);
      movementController.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 10),
      );

      final pos = movementController.updatePosition();

      // Sollte sich merklich in Richtung Ziel bewegt haben, aber noch nicht angekommen sein
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
      expect(movementController.isMoving, isTrue);
    });

    test('reaches target after enough time', () {
      movementController.moveTo(end);
      movementController.movementStartTime = DateTime.now().subtract(
        Duration(minutes: 10),
      );

      final pos = movementController.updatePosition();

      expect(pos.latitude, closeTo(end.latitude, 0.00001));
      expect(pos.longitude, closeTo(end.longitude, 0.00001));
      expect(movementController.isMoving, isFalse);
    });

    test('moveTo disables following and leading mode', () {
      movementController.isFollowing = true;
      movementController.isLeading = true;

      movementController.moveTo(end);

      expect(movementController.isFollowing, isFalse);
      expect(movementController.isLeading, isFalse);
      expect(movementController.isMoving, isTrue);
      expect(movementController.toPosition, end);
    });

    test('moveTo does not overwrite toPosition with playerPosition if was following before', () {
      movementController.startFollowing();
      //movementController.playerPosition = LatLng(51.5000, -0.1278); // weiter weg
      movementController.getPlayerPosition = () => LatLng(51.5000, -0.1278);


      final customTarget = end;

      movementController.moveTo(customTarget);
      movementController.movementStartTime = DateTime.now().subtract(Duration(seconds: 2));

      final pos = movementController.updatePosition();

      // NPC sollte sich in Richtung `end` bewegen, nicht zum Spieler
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(customTarget.latitude));
      expect(movementController.toPosition, customTarget);
      expect(movementController.isFollowing, isFalse);
    });

    test('stops following when close to player', () {
      movementController.startFollowing();
      //movementController.playerPosition = end;
      movementController.getPlayerPosition = () => end;
      movementController.currentBasePosition = end;
      movementController.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 1),
      );

      // simulate movement update
      final pos = movementController.updatePosition();

      expect(movementController.isMoving, isFalse);
      expect(pos.latitude, closeTo(end.latitude, 0.00001));
    });

    test('leads and waits if player is too far behind', () {
      movementController.leadTo(end);
      //movementController.playerPosition = start;
      movementController.getPlayerPosition = () => start;
      movementController.movementStartTime = DateTime.now().subtract(
        Duration(seconds: 80),
      );

      final pos = movementController.updatePosition();

      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
      expect(movementController.isMoving, isFalse);
    });

    test('onEnterRange is triggered when NPC comes into range', () {
      bool triggered = false;

      movementController = NPCMovementController(
        currentBasePosition: LatLng(51.5070, -0.1278),
        toPosition: LatLng(51.5075, -0.1278), // läuft Richtung Spieler
        speedInKmh: 3.6,
        onEnterRange: () => triggered = true,
        onExitRange: () {},
        getPlayerPosition: () => LatLng(51.5074, -0.1278),
      );

      movementController.moveTo(LatLng(51.5075, -0.1278));
      movementController.movementStartTime = DateTime.now().subtract(Duration(seconds: 10));

      movementController.updatePosition();

      expect(triggered, isTrue);
    });

    test('onExitRange is triggered when NPC leaves range', () {
      bool exited = false;

      movementController = NPCMovementController(
        currentBasePosition: LatLng(51.5074, -0.1278),
        toPosition: LatLng(51.5150, -0.1278), // weiter weg als conversationDistance
        speedInKmh: 3.6,
        onEnterRange: () {},
        onExitRange: () => exited = true,
        getPlayerPosition: () => LatLng(51.5074, -0.1278), // Spieler bleibt
      );

      movementController.moveTo(movementController.toPosition);
      movementController.updatePlayerProximity(); // jetzt: inRange
      movementController.movementStartTime = DateTime.now().subtract(Duration(minutes: 3));
      movementController.updatePosition();

      expect(exited, isTrue);
    });


    test('NPC starts following if player gets too far away', () {
      final playerStart = LatLng(51.5074, -0.1278);
      final farPlayer = LatLng(51.5090, -0.1278); // > 5m entfernt

      movementController = NPCMovementController(
        currentBasePosition: playerStart,
        toPosition: playerStart,
        speedInKmh: 3.6,
        onEnterRange: () {},
        onExitRange: () {},
        getPlayerPosition: () => farPlayer,
      );

      movementController.startFollowing(); // setzt isFollowing = true
      movementController.isMoving = false; // Stoppen erzwingen

      final posBefore = movementController.currentPosition;

      movementController.updatePosition();

      expect(movementController.isMoving, isTrue);
      expect(movementController.toPosition.latitude, farPlayer.latitude);
      expect(movementController.currentPosition.latitude, posBefore.latitude); // noch nicht bewegt
    });

    test('NPC stops following when close enough to player', () {
      final player = LatLng(51.5074, -0.1278);

      movementController = NPCMovementController(
        currentBasePosition: LatLng(51.5070, -0.1278),
        toPosition: player,
        speedInKmh: 3.6, // 1 m/s
        onEnterRange: () {},
        onExitRange: () {},
        getPlayerPosition: () => player,
      );

      movementController.startFollowing();
      movementController.movementStartTime = DateTime.now().subtract(Duration(seconds: 50));

      final pos = movementController.updatePosition();

      print('Distance to player: ${movementController.currentDistance}');
      print('isMoving: ${movementController.isMoving}');

      expect(movementController.isMoving, isFalse);
      expect(pos.latitude, closeTo(player.latitude, 0.0001));
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
    late NPCMovementController movementController;
    final start = LatLng(51.5074, -0.1278); // London
    final wp1 = LatLng(51.5078, -0.1278); // ≈ 44m nördlich
    final wp2 = LatLng(51.5082, -0.1278); // ≈ 44m nördlich
    final wp3 = LatLng(51.5086, -0.1278); // ≈ 44m nördlich
    final end = wp3;

    setUp(() {
      movementController = NPCMovementController(
        currentBasePosition: start,
        toPosition: start,
        speedInKmh: 3.6, // 1 m/s
        onExitRange: () => {},
        onEnterRange: () => {},
        getPlayerPosition: () => LatLng(51.5074, -0.1278),
      );
    });

    test('moveAlong sets path and starts movement', () {
      movementController.moveAlong([wp1, wp2, wp3]);

      expect(movementController.isMoving, isTrue);
      expect(movementController.toPosition, wp1);
      expect(movementController.path.length, 2); // wp2, wp3 noch übrig
    });

    test('updatePosition progresses through multiple waypoints', () {
      movementController.moveAlong([wp1, wp2, wp3]);

      // Simuliere sehr lange vergangene Zeit
      movementController.movementStartTime = DateTime.now().subtract(Duration(seconds: 300));

      // Wiederholt Bewegung durchführen bis fertig
      while (movementController.isMoving) {
        movementController.updatePosition();
      }

      final pos = movementController.currentPosition;

      expect(pos.latitude, closeTo(end.latitude, 0.0001));
      expect(pos.longitude, closeTo(end.longitude, 0.0001));
      expect(movementController.path.isEmpty, isTrue);
      expect(movementController.isMoving, isFalse);
    });

    test('leadAlong behaves like moveAlong and sets isLeading', () {
      movementController.leadAlong([wp1, wp2]);

      expect(movementController.isMoving, isTrue);
      expect(movementController.isLeading, isTrue);
      expect(movementController.isFollowing, isFalse);
      expect(movementController.toPosition, wp1);
      expect(movementController.path.length, 1); // wp2
    });

    test('stops when player is too far behind while leading', () {
      movementController.leadAlong([wp1, wp2, wp3]);
      //npc.playerPosition = start;
      movementController.getPlayerPosition = () => start;

      movementController.movementStartTime = DateTime.now().subtract(Duration(seconds: 80));

      // Bewegung fortsetzen, bis NPC stehen bleibt
      while (movementController.isMoving) {
        movementController.updatePosition();
      }

      final pos = movementController.currentPosition;

      expect(movementController.isMoving, isFalse);
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(wp3.latitude)); // nicht ganz angekommen
    });

  });


}
