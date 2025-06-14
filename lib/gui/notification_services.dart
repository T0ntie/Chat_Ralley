import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:aitrailsgo/app_resources.dart';
import 'package:aitrailsgo/main.dart';
import 'package:aitrailsgo/services/log_service.dart';

class FlushBarService {
  static final FlushBarService _instance = FlushBarService._internal();

  factory FlushBarService() => _instance;

  FlushBarService._internal();

  void showFlushbar({
    required String title,
    required String message,
  }) {

    final context = navigatorKey.currentContext;

    if (context == null) {
      log.e('Invalid context, cannot show Flushbar.', stackTrace: StackTrace.current);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        titleText: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        messageText: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        icon: Icon(Icons.info_outline, color: Colors.white, size: 28),
        backgroundGradient: LinearGradient(
          colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadows: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        duration: Duration(seconds: 3),
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.all(12),
        flushbarPosition: FlushbarPosition.TOP,
        animationDuration: Duration(milliseconds: 500),
      ).show(context);

    });
  }
}
class SnackBarService {
  // Eine Methode für die Anzeige von SnackBars, die den Kontext und die Nachricht benötigt
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Optional: Weitere Methoden können hinzugefügt werden, um spezifischere SnackBars zu zeigen
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ResourceColors.errorSnack(context),
      ),
    );
  }


  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ResourceColors.successSnack(context),
      ),
    );
  }
}
