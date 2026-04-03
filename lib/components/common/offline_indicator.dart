import 'package:flutter/material.dart';

/// Overlay shown when the WebSocket connection is lost.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          color: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: const SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Connection lost \u2014 reconnecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
