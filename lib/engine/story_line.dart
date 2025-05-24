import 'package:storytrail/services/firebase_serice.dart';

import '../engine/hotspot.dart';
import '../engine/item.dart';
import 'package:latlong2/latlong.dart';
import '../engine/game_engine.dart';

import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String trailId;
  final String title;
  final List<Npc> npcs;
  final List<Hotspot> hotspotsList;
  final Map<String, Hotspot> hotspotMap;
  final Map<String, bool> flags;
  final List<Item> items;
  static final Map<String, LatLng> _positions = {};
  static final Map<String, List<LatLng>> _paths = {};

  static const storyLineURI = 'storyline.json';
  static const positionsURI = 'positions.json';

  StoryLine({
    required this.trailId,
    required this.title,
    required this.npcs,
    required this.hotspotsList,
    required this.flags,
    required this.items,
  }) : hotspotMap = {for (final hotspot in hotspotsList) hotspot.name: hotspot};

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
      print('❌ Fehler beim parsen der paths in $positionsURI:\n$e\n$stack');
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
        '❌ Fehler beim parsen der positions in $positionsURI:\n$e\n$stack',
      );
      rethrow;
    }
  }

  static List<LatLng> pathFromJson(Map<String, dynamic> json) {
    final List<LatLng> path;
    final p = json['path'];
    if (p is String && StoryLine._paths.containsKey(p)) {
      path = StoryLine._paths[p]!;
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
    final pos = json['position'];
    if (pos is String) {
      if (StoryLine._positions.containsKey(pos)) {
        return StoryLine._positions[pos]!;
      } else {
        throw FormatException(
          "❌ Position-Name '$pos' ist nicht in positions.json definiert.",
        );
      }
    }
    if (pos is Map<String, dynamic>) {
      return _latLngFromJson(pos);
    }
    throw FormatException("❌ Ungültiges Format für 'position': $pos");
  }

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final npcsJson = json['npcs'] as List;
      final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
      final hotspotsJsn = json['hotspots'] as List;
      final hotspots = hotspotsJsn.map((e) => Hotspot.fromJson(e)).toList();
      final rawFlags = (json['flags'] as Map<String, dynamic>);
      final flags = <String, bool>{
        for (final entry in rawFlags.entries)
          entry.key.norm: entry.value as bool,
      };

      final items =
          (json['items'] as List).map((e) => Item.fromJson(e)).toList();
      return StoryLine(
        trailId: json['trailId'],
        title: json['title'],
        npcs: npcs,
        hotspotsList: hotspots,
        flags: flags,
        items: items,
      );
    } catch (e, stack) {
      print('❌ Fehler im Json der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<StoryLine> loadStoryLine(String trail) async {
   final positionsUrl = "${trail}/${positionsURI}";
   final storyLineUrl = "${trail}/${storyLineURI}";
  try {
      final positionsJson = await FirebaseHosting.loadJsonFromUrl(positionsUrl);
      _positions.clear();
      _positions.addAll(StoryLine._namedPositionsFromJson(positionsJson));
      _paths.clear();
      _paths.addAll(StoryLine._namedPathsFromJson(positionsJson));
    } catch (e, stack) {
      print(
        '❌ Fehler beim Laden der Positions from $positionsUrl:\n$e\n$stack',
      );
      rethrow;
    }
    try {
      //String storyLineJsonString = await rootBundle.loadString(storyLineAsset);
      final storLineJson = await FirebaseHosting.loadJsonFromUrl(storyLineUrl);
      return await StoryLine.fromJsonAsync(storLineJson);
    } catch (e, stack) {
      print(
        '❌ Fehler beim Laden der Storyline from $storyLineUrl:\n$e\n$stack',
      );
      rethrow;
    }
  }
}
