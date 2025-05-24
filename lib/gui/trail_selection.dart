import 'package:flutter/material.dart';
import 'package:storytrail/engine/trail.dart';
import 'package:storytrail/services/firebase_serice.dart';

class TrailSelectionScreen extends StatefulWidget {
  final List<Trail> availableTrails;
  final void Function(String trailId) onTrailSelected;

  const TrailSelectionScreen({
    super.key,
    required this.availableTrails,
    required this.onTrailSelected,
  });

  @override
  State<TrailSelectionScreen> createState() => _TrailSelectionScreenState();
}

class _TrailSelectionScreenState extends State<TrailSelectionScreen> {
  String? _selectedTrailId;

  Trail? get selectedTrail {
    return widget.availableTrails
        .where((trail) => trail.trailId == _selectedTrailId)
        .cast<Trail?>()
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    if (widget.availableTrails.isNotEmpty) {
      _selectedTrailId = widget.availableTrails.first.trailId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        selectedTrail != null ?
        FirebaseHosting.loadImageWidget(
          "images/${selectedTrail!.coverImage}",
          fit: BoxFit.fitWidth,
        ): Image.asset("assets/images/cover.png", fit: BoxFit.fitWidth),
        //Image.asset('assets/logo/splash.png', fit: BoxFit.fitWidth),
        Positioned(
          top: 60,
          left: 25,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4.0),
              width: 70,
              height: 70,
              child: Image.asset(
                'assets/logo/StoryTrail.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Container(color: Colors.black.withAlpha((0.3 * 255).toInt())),
        Center(
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              // damit dein dunkler Hintergrund durchscheint
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      //'Der Fall der verschwundenen Tibia',
                      selectedTrail?.title ?? 'Kein Trail verfügbar',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Times new Roman',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[900],
                      // Hintergrund der Dropdown-Liste
                      style: TextStyle(color: Colors.white),
                      // Textfarbe der Auswahl
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                        // Dropdown-Feld-Hintergrund
                        labelText: 'Verfügbare Trails',
                        labelStyle: TextStyle(
                          color: Colors.orangeAccent.shade200,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orangeAccent.shade200,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orangeAccent.shade100,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orangeAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      value: _selectedTrailId,
                      items:
                          widget.availableTrails.map((trail) {
                            return DropdownMenuItem<String>(
                              value: trail.trailId,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                // wichtig für Baseline-Ausrichtung!
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      trail.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16, // optional anpassen
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "(${trail.currentDistance >= 1000 ? "${(trail.currentDistance / 1000).toStringAsFixed(1)} km" : "${trail.currentDistance.round()} m"} entfernt)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTrailId = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedTrailId == null
                              ? Colors
                                  .grey
                                  .shade700 // Farbe für deaktivierten Zustand
                              : Colors.orangeAccent.shade200,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.grey.shade700,
                      disabledForegroundColor: Colors.white70,
                    ),
                    onPressed:
                        _selectedTrailId == null
                            ? null
                            : () => widget.onTrailSelected(_selectedTrailId!),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Los geht’s'),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
