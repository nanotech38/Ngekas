import 'package:flutter/material.dart';

class BaseTemplate extends StatelessWidget {
  const BaseTemplate({
    super.key,
    required this.child,
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF134E4A),
        Color(0xFF0F766E),
        Color(0xFF0D9488),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  });

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(child: child),
      ),
    );
  }
}
