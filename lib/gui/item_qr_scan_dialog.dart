import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hello_world/gui/notification_services.dart';

class ItemQRScanDialog extends StatefulWidget {
  final String title;
  final String message;
  final String expectedQrCode;

  const ItemQRScanDialog({
    super.key,
    required this.title,
    required this.message,
    required this.expectedQrCode,
  });

  @override
  State<ItemQRScanDialog> createState() => _ItemQRScanDialogState();
}

class _ItemQRScanDialogState extends State<ItemQRScanDialog> {

  void _handleBarcode(String code) {
    print("in handle Barcode");
    print("Code scanned: $code");

    if (code == widget.expectedQrCode) {
      Navigator.of(context).pop(code); // ✅ Richtiger Code – zurückgeben
    } else {
      SnackBarService.showErrorSnackBar(context, "🚫 Falscher Code. Versuche es nochmal.");
      // ❌ Falscher Code – nicht schließen
    }

/*
    if (code == widget.expectedQrCode) {

      final item = null;//GameEngine().getItemByQrCode(code);
      if (item != null && !item.isOwned) {
        item.isOwned = true;
        //GameEngine().markItemAsNew(item);
        SnackBarService.showSuccessSnackBar(context, "🎉 Du hast ${item.name} gefunden!");
      } else {
        //SnackBarService.showInfoSnackBar(context, "🔁 Du hast dieses Item bereits.");
      }
    } else {
      SnackBarService.showErrorSnackBar(context, "🚫 Falscher Code. Versuche es nochmal.");
    }
*/
    //Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            Icon(Icons.qr_code_scanner, color: Colors.white70, size: 64),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      _handleBarcode(barcode.rawValue!);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
