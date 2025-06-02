import 'package:flutter/material.dart';

class ContinueGameDialog extends StatelessWidget {
  final DateTime saveDate;
  final VoidCallback onLoadGame;
  final VoidCallback onNewGame;

  const ContinueGameDialog({
    super.key,
    required this.saveDate,
    required this.onLoadGame,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = saveDate.day.toString().padLeft(2, '0');
    final month = saveDate.month.toString().padLeft(2, '0');
    final hour = saveDate.hour.toString().padLeft(2, '0');
    final minute = saveDate.minute.toString().padLeft(2, '0');
    final formattedDate =
        '$day.$month.${saveDate.year} – $hour:$minute';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Spielstand gefunden!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Text(
              'Gespeichert am: $formattedDate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Text(
              'Möchtest du dein Spiel fortsetzen oder neu beginnen?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onLoadGame();
                        },
                        child: const Text('Spiel fortsetzen'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    //const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onNewGame();
                        },
                        child: const Text('Neu beginnen'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}