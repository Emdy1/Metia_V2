import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/js_core/anime.dart';
import 'package:metia/js_core/script_executor.dart';
import 'package:metia/models/anime_database.dart';
import 'package:metia/models/anime_database_service.dart';
import 'package:metia/models/episode_data_service.dart';
import 'package:metia/models/episode_database.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:metia/widgets/custom_tab.dart';
import 'package:provider/provider.dart';

class EpisodeItem extends StatelessWidget {
  final int index;
  final int animeId;
  final int extensionId;
  final bool current;
  final bool seen;
  final MetiaEpisode episode;
  final String title;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const EpisodeItem({
    super.key,
    required this.index,
    required this.animeId,
    required this.extensionId,
    required this.current,
    required this.seen,
    required this.episode,
    required this.title,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // CRITICAL OPTIMIZATION: Use Selector instead of context.watch()
    // This ensures ONLY this episode rebuilds when its data changes
    return Selector<EpisodeDataService, EpisodeData?>(
      selector: (_, service) =>
          service.getEpisodeDataOf(animeId, extensionId, index),
      shouldRebuild: (prev, next) {
        // Only rebuild if progress actually changed
        return prev?.progress != next?.progress || prev?.total != next?.total;
      },
      builder: (context, epData, _) {
        final percentage = epData != null && epData.total! > 0
            ? (epData.progress! / epData.total!) * 100
            : 0.0;

        return _EpisodeItemContent(
          index: index,
          current: current,
          seen: seen,
          episode: episode,
          title: title,
          scheme: scheme,
          percentage: percentage,
          onTap: onTap,
        );
      },
    );
  }
}

/// OPTIMIZATION: Separate the UI into its own widget
/// This allows better const optimization and cleaner code
class _EpisodeItemContent extends StatelessWidget {
  final int index;
  final bool current;
  final bool seen;
  final MetiaEpisode episode;
  final String title;
  final ColorScheme scheme;
  final double percentage;
  final VoidCallback onTap;

  const _EpisodeItemContent({
    required this.index,
    required this.current,
    required this.seen,
    required this.episode,
    required this.title,
    required this.scheme,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: Calculate colors once
    final currentBackgroundColor = scheme.primaryContainer;
    final backgroundColor = scheme.surfaceContainerHighest;
    final currentTextColor = scheme.onPrimaryContainer;
    final normalTextColor = scheme.onSurface;
    final secondaryTextColor = scheme.onSurfaceVariant;
    final progressBarColor = current ? scheme.primary : scheme.secondary;

    return GestureDetector(
      onTapUp: (_) => onTap(),
      // OPTIMIZATION: Use Material with InkWell for better performance
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: 108,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Stack(
            children: [
              // ===== Progress bar (only if there's progress) =====
              if (percentage > 0)
                _ProgressBar(
                  percentage: percentage,
                  backgroundColor: backgroundColor,
                  progressBarColor: progressBarColor,
                ),

              // ===== Main background =====
              Container(
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: current ? currentBackgroundColor : backgroundColor,
                ),
              ),

              // ===== Content =====
              Opacity(
                opacity: seen ? 0.45 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        // Thumbnail
                        _EpisodeThumbnail(posterUrl: episode.poster),

                        // Text content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: _EpisodeTextContent(
                              title: title,
                              episodeName: episode.name,
                              isSub: episode.isSub,
                              isDub: episode.isDub,
                              current: current,
                              currentTextColor: currentTextColor,
                              normalTextColor: normalTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== Seen check =====
              if (seen) const _SeenCheckIcon(),

              // ===== Episode number badge =====
              _EpisodeNumberBadge(
                episodeNumber: index + 1,
                current: current,
                backgroundColor: current
                    ? currentBackgroundColor
                    : backgroundColor,
                textColor: current ? currentTextColor : normalTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// OPTIMIZATION: Extract progress bar to separate widget
class _ProgressBar extends StatelessWidget {
  final double percentage;
  final Color backgroundColor;
  final Color progressBarColor;

  const _ProgressBar({
    required this.percentage,
    required this.backgroundColor,
    required this.progressBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 50,
          width: double.infinity,
          color: backgroundColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(color: progressBarColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// OPTIMIZATION: Extract thumbnail to separate widget with const constructor
class _EpisodeThumbnail extends StatelessWidget {
  final String posterUrl;

  const _EpisodeThumbnail({required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: posterUrl,
            fit: BoxFit.cover,
            // OPTIMIZATION: Add memory cache configuration
            memCacheHeight: 100,
            memCacheWidth: 177, // 16:9 ratio
            maxHeightDiskCache: 200,
            maxWidthDiskCache: 355,
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
            // OPTIMIZATION: Add placeholder for better UX
            placeholder: (_, __) => Container(color: Colors.grey.shade900),
          ),
        ),
      ),
    );
  }
}

/// OPTIMIZATION: Extract text content to reduce nesting
class _EpisodeTextContent extends StatelessWidget {
  final String title;
  final String episodeName;
  final bool isSub;
  final bool isDub;
  final bool current;
  final Color currentTextColor;
  final Color normalTextColor;
  final Color secondaryTextColor;

  const _EpisodeTextContent({
    required this.title,
    required this.episodeName,
    required this.isSub,
    required this.isDub,
    required this.current,
    required this.currentTextColor,
    required this.normalTextColor,
    required this.secondaryTextColor,
  });

  String get audioFormat {
    if (isSub && isDub) return "Sub | Dub";
    if (isSub) return "Sub";
    if (isDub) return "Dub";
    return "not specified";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: current ? currentTextColor : secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              episodeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: current ? currentTextColor : normalTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              audioFormat,
              style: TextStyle(
                color: current
                    ? currentTextColor.withOpacity(0.8)
                    : secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OPTIMIZATION: Seen check as const widget
class _SeenCheckIcon extends StatelessWidget {
  const _SeenCheckIcon();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 4,
      child: SizedBox(
        height: 100,
        width: 177.78,
        child: Center(
          child: Icon(Icons.check_circle, size: 60, color: Colors.white70),
        ),
      ),
    );
  }
}

/// OPTIMIZATION: Episode badge as separate widget
class _EpisodeNumberBadge extends StatelessWidget {
  final int episodeNumber;
  final bool current;
  final Color backgroundColor;
  final Color textColor;

  const _EpisodeNumberBadge({
    required this.episodeNumber,
    required this.current,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Transform.translate(
          offset: const Offset(0, 4.1),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              '$episodeNumber',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
