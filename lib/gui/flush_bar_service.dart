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
        titleColor: Colors.white,
        messageColor: Colors.white,
      ).show(_context);
    });
  }
}
