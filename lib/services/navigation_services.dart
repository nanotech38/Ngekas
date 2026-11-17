import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:page_transition/page_transition.dart';

class NavigationService {
  static const tag = 'NavigationService';

  static final NavigationService _instance = NavigationService._();
  static NavigationService get() => _instance;

  NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> push(Widget screenWidget) {
    AppLog.i(tag, 'push: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.push(
      PageTransition(type: PageTransitionType.fade, child: screenWidget),
    );
  }

  Future<dynamic> pushReplacement(Widget screenWidget) {
    AppLog.i(tag, 'pushReplacement: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.pushReplacement(
      PageTransition(
        type: PageTransitionType.fade,
        reverseDuration: Duration(milliseconds: 100),
        duration: Duration(milliseconds: 100),
        child: screenWidget,
      ),
    );
  }

  Future<dynamic> pushAndRemoveAll(Widget screenWidget) {
    AppLog.i(tag, 'pushAndRemoveAll: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.pushAndRemoveUntil(
      PageTransition(type: PageTransitionType.fade, child: screenWidget),
      (Route<dynamic> route) => false,
    );
  }

  Future<dynamic> pushAndRemoveUntilHome(Widget screenWidget) {
    AppLog.i(
      tag,
      'pushAndRemoveUntilHome: ${screenWidget.runtimeType.toString()}',
    );
    return navigatorKey.currentState!.pushAndRemoveUntil(
      PageTransition(type: PageTransitionType.fade, child: screenWidget),
      (Route<dynamic> route) {
        if (route.isFirst) {
          return true;
        } else {
          return false;
        }
      },
    );
  }

  dynamic pop<T extends Object>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  void popUntilHome() {
    AppLog.i(tag, 'popUntilHome');
    return navigatorKey.currentState!.popUntil((Route<dynamic> route) {
      if (route.isFirst) {
        return true;
      } else {
        return false;
      }
    });
  }

  void killApps() {
    if (Platform.isAndroid) {
      try {
        exit(0);
      } catch (e) {
        SystemNavigator.pop();
      }
    } else if (Platform.isIOS) {
      exit(0);
    }
  }
}
