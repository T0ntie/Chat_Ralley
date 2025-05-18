import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const SplashScreen({super.key, required this.onContinue});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/logo/splash.png',
          fit: BoxFit.fitWidth,
        ),
        Positioned(
          top: 60,
          left: 25,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
              width: 70,
              height: 70,
              child: Image.asset(
                'assets/logo/StoryTrail.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        Container(
          color: Colors.black.withAlpha((0.3 * 255).toInt()), // dunkler Filter
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 15),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child:
                Text(
                  'Der Fall der verschwundenen Tibia',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily:'Times new Roman',
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
              const Spacer(flex: 5),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent.shade200,
                  foregroundColor: Colors.black87,
                ),
                onPressed: widget.onContinue,
                icon: Icon(Icons.play_arrow),
                label: Text('Los geht’s'),
              ),
              SizedBox(height: 60),
            ],
          ),
        )
      ],
    );
  }
}
