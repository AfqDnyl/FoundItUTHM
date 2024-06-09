// common_background.dart
import 'package:flutter/material.dart';

class CommonBackground extends StatelessWidget {
  final Widget child;

  CommonBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.1, // Set the opacity here
            child: Image.asset(
              'lib/assets/lost_found_new_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        child,
      ],
    );
  }
}