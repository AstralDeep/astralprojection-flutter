import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Full-screen overlay with blurred background, spinner, and rotating
/// humorous messages. Shown between authentication and first ui_render.
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  static const _messages = [
    'Loading...',
    'Reticulating Splines...',
    'Warming up the flux capacitor...',
    'Consulting the oracle...',
    'Aligning the stars...',
    'Brewing digital coffee...',
    'Counting backwards from infinity...',
    'Untangling the wires...',
    'Calibrating the astral plane...',
    'Almost there...',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        // Centered spinner and message
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_index],
                  key: ValueKey(_index),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
