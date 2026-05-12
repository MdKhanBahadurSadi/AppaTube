import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PlayButtonWidget extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const PlayButtonWidget({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 64,
  });

  @override
  State<PlayButtonWidget> createState() => _PlayButtonWidgetState();
}

class _PlayButtonWidgetState extends State<PlayButtonWidget> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isTapped ? 0.95 : 1.0,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.red, Color(0xFF8B0000)],
            ),
            boxShadow: [
              if (widget.isPlaying)
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey<bool>(widget.isPlaying),
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
