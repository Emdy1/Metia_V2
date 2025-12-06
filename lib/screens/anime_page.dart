import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:provider/provider.dart';

class AnimePage extends StatefulWidget {
  final MediaListEntry anime;
  const AnimePage({super.key, required this.anime});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            foregroundColor: Provider.of<ThemeProvider>(context).scheme.primary,
            backgroundColor: Provider.of<ThemeProvider>(context).scheme.background,
            surfaceTintColor: Provider.of<ThemeProvider>(context).scheme.background,
            pinned: true,
            title: false ? Text(widget.anime.media.title.english ?? "No Title") : Text(""),
            expandedHeight: (MediaQuery.of(context).size.height) * 0.7,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: widget.anime.media.coverImage.extraLarge,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,

                      // When the image loads, fade in
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Provider.of<ThemeProvider>(context).scheme.background.withOpacity(0.8),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.4], // control where each color stops
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(0, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Provider.of<ThemeProvider>(context).scheme.background],
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      SafeArea(
                        child: SizedBox(
                          height: kToolbarHeight,
                          child: Builder(
                            builder: (context) {
                              final nextAiring =
                                  widget.anime.media.nextAiringEpisode;
                              if (nextAiring == null) {
                                return const SizedBox();
                              }
                              final int airingAt = nextAiring.airingAt ?? 0;
                              final int episode = nextAiring.episode ?? 0;
                              final Duration diff =
                                  DateTime.fromMillisecondsSinceEpoch(
                                    airingAt * 1000,
                                  ).difference(DateTime.now());
                              if (diff.isNegative) return const SizedBox();

                              final int days = diff.inDays;
                              final int hours = diff.inHours % 24;
                              final int minutes = diff.inMinutes % 60;

                              String timeString = '';
                              if (days > 0) timeString += '${days}d ';
                              if (hours > 0 || days > 0)
                                timeString += '${hours}h ';
                              timeString += '${minutes}m';

                              return SafeArea(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Colors.orange,
                                      size: 22,
                                    ),
                                    Text(
                                      ' Episode $episode: $timeString',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        //shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            bottom: 16.0,
                            right: 16.0,
                          ),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.orientationOf(context) ==
                                      Orientation.landscape
                                  ? 20
                                  : 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.anime.media.title.english ??
                                      "No Title",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (widget.anime.media.genres ?? []).join(' • '),
                                  style: const TextStyle(
                                    color: Color(0xFFA9A7A7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.anime.media.averageScore
                                                  .toString() ==
                                              "null"
                                          ? "0.0"
                                          : "${(widget.anime.media.averageScore! / 10).toStringAsFixed(1)}",

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Synopsis",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.anime.media.description ??
                                      "".replaceAll(RegExp(r'<[^>]*>'), ''),
                                  maxLines: 8,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    height: 1.1,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFA9A7A7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              stretchModes: const [
                StretchMode.blurBackground,
                StretchMode.zoomBackground,
              ],
            ),
          ),

          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              toolbarHeight: 179,
              expandedHeight: 179,
              collapsedHeight: 179,
              pinned: true,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).orientation ==
                            Orientation.landscape
                        ? 23
                        : 0,
                  ),
                  color: Provider.of<ThemeProvider>(context).scheme.background,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 12,
                      right: 12,
                      bottom: 12,
                    ),
                    child: Placeholder(
                      //TODO: here is where the extension picker and found name and "wrong?" is going to be in the future
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        //spacing: 5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Container(),
      ),
    );
  }
}
