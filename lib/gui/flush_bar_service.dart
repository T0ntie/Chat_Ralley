import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

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
    required IconData icon,
    required Color backgroundColor,
  }) {
    if (_context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        title: title,
        message: message,
        icon: Icon(icon, color: Colors.white),
        duration: Duration(seconds: 3),
        backgroundColor: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        margin: EdgeInsets.all(8),
        animationDuration: Duration(milliseconds: 500),
        flushbarPosition: FlushbarPosition.TOP,
        titleColor: Colors.white,
        messageColor: Colors.white,
      ).show(_context);
    });
  }
}
