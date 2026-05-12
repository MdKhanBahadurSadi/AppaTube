import 'package:flutter/material.dart';
import '../../core/constants/play_mode.dart';

class PlayModeToggle extends StatelessWidget {
  final PlayMode currentMode;
  final Function(PlayMode) onModeChanged;

  const PlayModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              mode: PlayMode.audio,
              isSelected: currentMode == PlayMode.audio,
              onTap: () => onModeChanged(PlayMode.audio),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              mode: PlayMode.video,
              isSelected: currentMode == PlayMode.video,
              onTap: () => onModeChanged(PlayMode.video),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final PlayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE40000) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == PlayMode.audio
                  ? Icons.headphones_rounded
                  : Icons.videocam_rounded,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              mode == PlayMode.audio ? 'Audio' : 'Video',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF666666),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
