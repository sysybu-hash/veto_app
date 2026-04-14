import 'package:flutter/material.dart';
import 'landing_screen.dart' as rich_landing;

/// Compatibility wrapper:
/// ensures any import of `LandingScreen.dart` renders the rich legacy landing.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const rich_landing.LandingScreen();
  }
}
