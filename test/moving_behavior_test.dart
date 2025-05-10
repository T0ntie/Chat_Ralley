import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hello_world/engine/npc.dart'; // Importiere deine MovingBehavior-Klasse

void main() {
  group('MovingBehavior', () {
    late MovingBehavior behavior;
    final start = LatLng(51.5074, -0.1278); // London
    final end = LatLng(51.5101, -0.1278); // ≈ 300 m nördlich

    setUp(() {
      behavior = MovingBehavior(
        currentBasePosition: start,
        toPosition: end,
        speedInKmh: 3.6, // 1 m/s
      );
    });

    test('initial position is currentBasePosition', () {
      expect(behavior.currentPosition.latitude, closeTo(start.latitude, 0.00001));
      expect(behavior.currentPosition.longitude, closeTo(start.longitude, 0.00001));
    });

    test('moves toward target over time', () {
      behavior.moveTo(end);

      // Simuliere 10 Sekunden vergangene Zeit
      behavior.movementStartTime = DateTime.now().subtract(Duration(seconds: 10));

      final pos = behavior.currentPosition;

      // Sollte sich merklich in Richtung Ziel bewegt haben, aber noch nicht angekommen sein
      expect(pos.latitude, greaterThan(start.latitude));
      expect(pos.latitude, lessThan(end.latitude));
    });

    test('reaches target after genug Zeit', () {
      behavior.moveTo(end);

      // Simuliere große Zeitspanne
      behavior.movementStartTime = DateTime.now().subtract(Duration(minutes: 10));

      final pos = behavior.currentPosition;

      expect(pos.latitude, closeTo(end.latitude, 0.00001));
      expect(pos.longitude, closeTo(end.longitude, 0.00001));
      expect(behavior.isMoving, isFalse);
    });

    test('stops following when close to player', () {
      behavior.startFollowing();
      behavior.playerPosition = end;

      // NPC ist schon nah genug
      behavior.currentBasePosition = end;
      behavior.movementStartTime = DateTime.now().subtract(Duration(seconds: 1));
      final pos = behavior.currentPosition;

      expect(behavior.isMoving, isFalse);
      expect(pos.latitude, closeTo(end.latitude, 0.00001));
    });

    test('leads and waits if player is too far behind', () {
      behavior.leadTo(end);
      behavior.playerPosition = start;

      // Spieler bleibt stehen, NPC sollte abbremsen
      behavior.movementStartTime = DateTime.now().subtract(Duration(seconds: 80));
      final pos = behavior.currentPosition;

      // Sollte irgendwo zwischen Start und Ziel sein, aber isMoving = false
      expect(pos.latitude, greaterThan(start.latitude));
      expect(behavior.isMoving, isFalse);
    });
  });
}
