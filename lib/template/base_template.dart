import 'package:flutter/material.dart';

class BaseTemplate extends StatelessWidget {
  const BaseTemplate({
    super.key,
    required this.child,
    this.appBar,
    this.backgroundColor,
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFC2410C),
        Color(0xFFEA580C),
        Color(0xFFF97316),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Gradient gradient;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    final useGradient = backgroundColor == null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: useGradient ? BoxDecoration(gradient: gradient) : null,
        child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: child),
      ),
    );
  }
}
