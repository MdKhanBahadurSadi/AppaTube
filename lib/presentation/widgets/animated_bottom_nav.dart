import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            index: 0,
            isSelected: currentIndex == 0,
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => onTap(0),
          ),
          _NavItem(
            index: 1,
            isSelected: currentIndex == 1,
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: () => onTap(1),
          ),
          _NavItem(
            index: 2,
            isSelected: currentIndex == 2,
            icon: Icons.history_rounded,
            label: 'History',
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 0,
              vertical: isSelected ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.red.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        icon,
                        color: isSelected ? AppColors.red : Colors.grey,
                        size: 24,
                      ),
                    );
                  },
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Active indicator (red dot)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
