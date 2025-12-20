import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/js_core/script_executor.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:provider/provider.dart';

class AnimePage extends StatefulWidget {
  final MediaListEntry anime;

  const AnimePage({super.key, required this.anime});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  final ScrollController scrollController = ScrollController();
  late final ExtensionRuntimeManager runtime;
  ScriptExecutor? executor;

  bool get isAppBarExpanded {
    return scrollController.hasClients &&
        scrollController.offset >
            (MediaQuery.of(context).size.height * 0.7) - kToolbarHeight - 30;
  }

  ColorScheme get scheme =>
      Provider.of<ThemeProvider>(context, listen: false).scheme;

  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      setState(() {});
    });
    runtime = context.read<ExtensionRuntimeManager>();

    executor = runtime.executor!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (nestedContext, innerBoxIsScrolled) => [
          buildAnimeInfo(),
          buildExtensionInfo(nestedContext),
        ],
        body: Container(),
      ),
    );
  }

  Widget buildExtensionInfo(nestedContext) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(nestedContext),
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
                  MediaQuery.of(context).orientation == Orientation.landscape
                  ? 23
                  : 0,
            ),
            color: scheme.background,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                left: 12,
                right: 12,
                bottom: 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                //spacing: 5,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      PopupMenuButton<String>(
                        //splashRadius: 0,
                        tooltip: "Select Extension",
                        onSelected: (String extensionId) async {},
                        itemBuilder: (BuildContext context) {
                          //TODO: load available extensions here
                          return [
                            PopupMenuItem<String>(
                              value: "no_extension",
                              child: Row(
                                children: [
                                  Icon(Icons.extension, color: scheme.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "No Extension Installed",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                        child: Column(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Icon(
                                  Icons.extension,
                                  color: scheme.primary,
                                ), // TODO: in the future, load extension icon here,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: scheme.primary),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Found:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "No Extension Selected",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: GestureDetector(
                          onTap: () {},

                          child: Text(
                            "Wrong?",
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Start Watching Button
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.green),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      label: Text(
                        widget.anime.media.episodes != null
                            ? widget.anime.media.episodes ==
                                      widget.anime.progress
                                  ? "FINISHED"
                                  : "CONTINUE EPISODE ${(widget.anime.progress ?? 0) + 1}"
                            : "NULL",
                        style: TextStyle(
                          color: runtime.ready.value
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon:
                          widget.anime.media.episodes != null &&
                              widget.anime.media.episodes !=
                                  widget.anime.progress
                          ? const Icon(Icons.play_arrow_outlined, size: 20)
                          : const SizedBox(),
                      onPressed: () async {
                        //TODO: Start or continue watching logic here
                        final results = await executor!.searchAnime("bleach");
                        for (var anime in results) {
                          Logger.log(anime.name);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  //Tab bar builder
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton(
                      onSelectionChanged: (value) {
                        selectedTabIndex = value.first;
                        setState(() {});
                      },
                      segments: List.generate(10, (index) {
                        final start = index == 0 ? 1 : index * 100;
                        final end = index * 100 + 99;

                        return ButtonSegment(
                          value: index,
                          label: Text(
                            '${start.toString().length == 1 ? "   $start-$end   " : "$start-$end"}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }),

                      selected: {selectedTabIndex},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAnimeInfo() {
    return SliverAppBar(
      foregroundColor: scheme.primary,
      backgroundColor: scheme.background,
      surfaceTintColor: scheme.background,
      pinned: true,
      title: AnimatedOpacity(
        opacity: isAppBarExpanded ? 1 : 0,
        duration: Duration(milliseconds: 100),
        child: Text(widget.anime.media.title.english ?? "No Title"),
      ),
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
                    Provider.of<ThemeProvider>(
                      context,
                    ).scheme.background.withOpacity(0.8),
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
                    colors: [Colors.transparent, scheme.background],
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
                        final nextAiring = widget.anime.media.nextAiringEpisode;
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
                        if (hours > 0 || days > 0) timeString += '${hours}h ';
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
                            widget.anime.media.title.english ?? "No Title",
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
                                widget.anime.media.averageScore.toString() ==
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
    );
  }
}
