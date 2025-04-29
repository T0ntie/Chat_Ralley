import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:hello_world/app_resources.dart';

class FlushBarService {
  static final FlushBarService _instance = FlushBarService._internal();

  factory FlushBarService() => _instance;

  FlushBarService._internal();

  late BuildContext _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  void showFlushbar({
    required String title,
    required String message,
  }) {
    //if (_context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        title: title,
        message: message,
        icon: AppIcons.notification(_context),
        duration: Duration(seconds: 3),
        backgroundColor: ResourceColors.notificationBackground(_context),
        borderRadius: BorderRadius.circular(8),
        margin: EdgeInsets.all(8),
        animationDuration: Duration(milliseconds: 500),
        flushbarPosition: FlushbarPosition.TOP,
        titleColor: ResourceColors.notificationTitle(_context),
        messageColor: ResourceColors.notificationMessage(_context),
      ).show(_context);
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
    print('message');
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
