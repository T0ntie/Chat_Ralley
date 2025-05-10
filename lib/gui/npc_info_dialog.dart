import '../engine/npc.dart';
import 'package:flutter/material.dart';

class NpcInfoDialog extends StatelessWidget
{
  final Npc npc;
  final void Function(Npc npc) onNpcChatRequested;
  const NpcInfoDialog({super.key, required this.npc, required this.onNpcChatRequested,});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent, // Für Gradient
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
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
              npc.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/story/${npc.displayImageAsset}",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entfernung: ${npc.currentDistance} Meter',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (!npc.isInCommunicationDistance())
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Komm näher, um mit ${npc.displayName} zu kommunizieren.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: npc.isInCommunicationDistance()
                      ? () {
                    Navigator.of(context).pop();
                    onNpcChatRequested(npc);
                  }
                      : null,
                  icon: Icon(Icons.chat),
                  label: Text('Chat starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey.shade900,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

/*
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${npc.displayName}', style: TextStyle(fontSize: 18),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150, // oder was dir gefällt
            height: 150,
            child: Image.asset("assets/story/${npc.displayImageAsset}",
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 10),
          Text('${npc.displayName}'),
          */
/*Text(
            'Position: ${npc.position.latitude.toStringAsFixed(3)}, ${npc.position.longitude.toStringAsFixed(3)}',
          ),*//*

          Text('Entfernung: ${npc.currentDistance} Meter'),
          SizedBox(height: 10),
          if (!npc.canCommunicate())
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Komm näher, um mit ${npc.displayName} zu kommunizieren.",
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: <Widget>[
          TextButton(
            child: Text('Chat starten'),
            onPressed: npc.canCommunicate()
                ? () {
              Navigator.of(context).pop(); // Erst den Dialog schließen
              onNpcChatRequested.call(npc);
              */
/*
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(npc: npc),
                ),
              );
              *//*

            }
                : null,
          ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(); // Dialog schließen
          },
        ),
      ],
    );
  }
*/

}