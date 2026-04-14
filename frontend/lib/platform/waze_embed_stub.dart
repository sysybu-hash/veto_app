import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Non-web / fallback: open Waze in external app or browser.
void registerWazeEmbed(String viewId, String wazeUrl) {}

Widget buildWazeEmbed(String viewId, String wazeUrl) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, size: 56, color: Color(0xFFB8941E)),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            ),
            onPressed: () => launchUrl(
              Uri.parse(wazeUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('פתח מפת Waze', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ),
  );
}
