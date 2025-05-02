import '../engine/npc.dart';
import 'package:flutter/material.dart';
import 'chat/chat_page.dart';

class NpcInfoDialog extends StatelessWidget
{
  final Npc npc;

  const NpcInfoDialog({super.key, required this.npc,});

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
          /*Text(
            'Position: ${npc.position.latitude.toStringAsFixed(3)}, ${npc.position.longitude.toStringAsFixed(3)}',
          ),*/
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(npc: npc),
                ),
              );
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



}