import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:page_transition/page_transition.dart';

class NavigationService {
  static const tag = 'NavigationService';

  static NavigationService _instance = NavigationService._();
  static NavigationService get() => _instance;

  NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> push(Widget screenWidget) {
    debugPrint('[$tag] push: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!
        .push(PageTransition(type: PageTransitionType.fade, child: screenWidget));
  }

  // route sekarang dihapus -> next page
  Future<dynamic> pushReplacement(Widget screenWidget) {
    debugPrint('[$tag] pushReplacement: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.pushReplacement(PageTransition(
        type: PageTransitionType.fade,
        reverseDuration: Duration(milliseconds: 100),
        duration: Duration(milliseconds: 100),
        child: screenWidget));
  }

  // Hapus semua route -> next page
  Future<dynamic> pushAndRemoveAll(Widget screenWidget) {
    debugPrint('[$tag] pushAndRemoveAll: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.pushAndRemoveUntil(
        PageTransition(type: PageTransitionType.fade, child: screenWidget),
            (Route<dynamic> route) => false);
  }

  // Hapus semua route kecuali halaman pertama (home) -> next page
  Future<dynamic> pushAndRemoveUntilHome(Widget screenWidget) {
    debugPrint('[$tag] pushAndRemoveUntilHome: ${screenWidget.runtimeType.toString()}');
    return navigatorKey.currentState!.pushAndRemoveUntil(
        PageTransition(type: PageTransitionType.fade, child: screenWidget), (Route<dynamic> route) {
      if (route.isFirst)
        return true;
      else
        return false;
    });
  }

  dynamic pop<T extends Object>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  // Kembali terus sampai di halaman pertama (home)
  void popUntilHome() {
    debugPrint('[$tag] popUntilHome');
    return navigatorKey.currentState!.popUntil((Route<dynamic> route) {
      if (route.isFirst)
        return true;
      else
        return false;
    });
  }

  // Tutup aplikasi sepenuhnya
  void killApps(){
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
