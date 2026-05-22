import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Subtle animated gradient mesh used behind scrollable content.
class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1, 1 - t * 0.4),
              colors: [
                AppColors.background,
                Color.lerp(
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0.18),
                  t,
                )!,
                AppColors.background,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
