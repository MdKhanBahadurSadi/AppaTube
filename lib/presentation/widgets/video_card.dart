import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final bool isPlaying;
  final String heroContext;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.isPlaying = false,
    required this.heroContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPlaying ? AppColors.red.withValues(alpha: 0.05) : Colors.transparent,
        border: isPlaying
            ? const Border(
                left: BorderSide(color: AppColors.red, width: 3),
              )
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT — Stack for Thumbnail and Badges
              Stack(
                children: [
                  Hero(
                    tag: 'thumb_${heroContext}_${video.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        width: 120,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 72,
                          color: AppColors.surfaceHigh,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 72,
                          color: AppColors.surfaceHigh,
                          child: const Icon(Icons.error, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  if (isPlaying) ...[
                    // Playing Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red, width: 2),
                        ),
                        child: const Center(
                          child: EqualizerAnimation(size: 28),
                        ),
                      ),
                    ),
                  ],
                  // Duration Badge
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatDuration(video.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // RIGHT — Expanded Column for Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? AppColors.red : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            video.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          formatDuration(video.duration),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EqualizerAnimation extends StatefulWidget {
  final double size;

  const EqualizerAnimation({super.key, this.size = 28});

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _barCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 150)),
      )..repeat(reverse: true),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.size / (_barCount * 2),
                height: widget.size * _animations[index].value,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
