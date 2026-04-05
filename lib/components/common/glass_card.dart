import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glass-morphism card widget matching the React `.glass-card` CSS
/// styling. Applies a frosted-glass backdrop blur with a semi-transparent
/// dark surface and subtle white border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1E2E).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
