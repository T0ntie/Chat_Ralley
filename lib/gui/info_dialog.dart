import 'package:flutter/material.dart';
import 'package:storytrail/services/firebase_serice.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  //final String imageAssetPath;
  final String imageUriPath;
  final String distanceText;
  final String? noteText;
  final void Function()? onPrimaryAction;
  final String primaryActionLabel;

  const InfoDialog({
    super.key,
    required this.title,
    //required this.imageAssetPath,
    required this.imageUriPath,
    required this.distanceText,
    this.noteText,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Gespräch beginnen',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
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
                  child: FirebaseHosting.loadImageWidget(imageUriPath, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              distanceText,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (noteText != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  noteText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onPrimaryAction != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPrimaryAction!();
                    },
                    icon: const Icon(Icons.chat),
                    label: Text(primaryActionLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueGrey.shade900,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (onPrimaryAction != null) const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
