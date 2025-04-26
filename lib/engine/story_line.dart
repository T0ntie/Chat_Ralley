import 'package:hello_world/engine/hotspot.dart';
import 'package:latlong2/latlong.dart';

import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String scenarioId;
  final String title;
  final List<Npc> npcs;
  final List<Hotspot> hotspotsList;
  final Map<String, Hotspot> hotspotMap;
  final Map<String, bool> flags;
  static final Map<String, LatLng> positions = {};
  static final Map<String, List<LatLng>> paths = {};

  static const storyLineAsset = 'assets/story/storyline.json';
  static const positionsAsset = 'assets/story/positions.json';

  StoryLine({
    required this.scenarioId,
    required this.title,
    required this.npcs,
    required this.hotspotsList,
    required this.flags,
  }) : hotspotMap = Map<String, Hotspot>.fromIterable(
    hotspotsList,
    key: (hotspot) => hotspot.name,
    value: (hotspot) => hotspot,
  );

  static LatLng _latLngFromJson(Map<String, dynamic> json) {
    if (json.containsKey('lat') && json.containsKey('lng')) {
      return LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
    }
    throw FormatException("Missing or invalid Lat/Lng in $json");
  }

  static Map<String, List<LatLng>> _namedPathsFromJson(
    Map<String, dynamic> json,
  ) {
    try {
      final pathJson = json['paths'] as Map<String, dynamic>;
      return pathJson.map((key, value) {
        List<LatLng> path =
            (value as List<dynamic>).map((p) {
              return _latLngFromJson(p);
            }).toList();
        return MapEntry(key, path);
      });
    } catch (e, stack) {
      print('❌ Fehler beim parsen der paths in $positionsAsset:\n$e\n$stack');
      rethrow;
    }
  }

  static Map<String, LatLng> _namedPositionsFromJson(
    Map<String, dynamic> json,
  ) {
    try {
      final positionJson = json['positions'] as Map<String, dynamic>;
      return positionJson.map((key, value) {
        final latLng = _latLngFromJson(value);
        return MapEntry(key, latLng);
      });
    } catch (e, stack) {
      print(
        '❌ Fehler beim parsen der positions in $positionsAsset:\n$e\n$stack',
      );
      rethrow;
    }
  }

  static List<LatLng> pathFromJson(Map<String, dynamic> json) {
    final List<LatLng> path;
    final p = json['path'];
    if (p is String && StoryLine.paths.containsKey(p)) {
      path = StoryLine.paths[p]!;
      print("Found Path in Pathmap: $path");
    } else {
      path =
          p.map((e) {
            final lat = e['lat'] as double;
            final lng = e['lng'] as double;
            return LatLng(lat, lng);
          }).toList();
    }
    return path;
  }

  static LatLng positionFromJson(Map<String, dynamic> json) {
    //check vor valid position
    final LatLng position;
    final pos = json['position'];
    if (pos is String && StoryLine.positions.containsKey(pos)) {
      position = StoryLine.positions[pos]!;
      print("Found Position in Positionmap: $pos");
    } else {
      position = _latLngFromJson(pos);
    }
    return position;
  }

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final npcsJson = json['npcs'] as List;
      final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
      final hotspotsJsn = json['hotspots'] as List;
      final hotspots = hotspotsJsn.map((e) => Hotspot.fromJson(e)).toList();
      final flags =
          (json['flags'] as Map<String, dynamic>).cast<String, bool>();
      return StoryLine(
        scenarioId: json['scenarioId'],
        title: json['title'],
        npcs: npcs,
        hotspotsList: hotspots,
        flags: flags,
      );
    } catch (e, stack) {
      print('❌ Fehler im Json der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<StoryLine> loadStoryLine() async {
    try {
      final positionsJsonString = await rootBundle.loadString(positionsAsset);
      final positionsJson = json.decode(positionsJsonString);
      positions.addAll(StoryLine._namedPositionsFromJson(positionsJson));
      paths.addAll(StoryLine._namedPathsFromJson(positionsJson));
      print("found the following paths: $paths");
    } catch (e, stack) {
      print(
        '❌ Fehler beim Laden der Positions from $positionsAsset:\n$e\n$stack',
      );
      rethrow;
    }
    try {
      final storyLineJsonString = await rootBundle.loadString(storyLineAsset);
      final storLineJson = json.decode(storyLineJsonString);
      return await StoryLine.fromJsonAsync(storLineJson);
    } catch (e, stack) {
      print(
        '❌ Fehler beim Laden der Storyline from $storyLineAsset:\n$e\n$stack',
      );
      rethrow;
    }
  }
}
