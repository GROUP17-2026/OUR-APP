import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted glass panel with subtle border (glassmorphism).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 1. Move the Material widget to the root of the card structure
    // This ensures TextField and InkWell both have what they need.
    return Material(
      color: Colors.transparent, // Keeps the glass effect visible
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias, // Ensures the splash doesn't bleed out
      child: InkWell(
        onTap: onTap,
        // Disable splash/highlight if no onTap is provided
        splashColor: onTap == null ? Colors.transparent : null,
        highlightColor: onTap == null ? Colors.transparent : null,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.cardSurface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
