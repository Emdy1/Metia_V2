import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/js_core/anime.dart';
import 'package:metia/js_core/script_executor.dart';
import 'package:metia/models/anime_data_service.dart';
import 'package:metia/models/episode_database.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:provider/provider.dart';

class AnimePage extends StatefulWidget {
  final MediaListEntry anime;

  const AnimePage({super.key, required this.anime});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();
  late final ExtensionRuntimeManager runtime;
  ScriptExecutor? executor;
  List<Extension>? currentExtensions;

  bool get isAppBarExpanded {
    return scrollController.hasClients &&
        scrollController.offset >
            (MediaQuery.of(context).size.height * 0.5) - kToolbarHeight - 30;
  }

  ColorScheme get scheme =>
      Provider.of<ThemeProvider>(context, listen: false).scheme;

  int selectedTabIndex = 0;

  late MetiaAnime? matchedAnime;

  int itemCount = 1;
  int firstTabCount = 99;
  int eachItemForTab = 100;
  int tabCount = 1;
  List<String> labels = ["0 - 0"];
  List<int> tabItemCounts = [0];
  List<MetiaEpisode> episodeList = [];
  String foundTitle = "";

  bool isSearching = true;
  bool isGettingEpisodes = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    scrollController.addListener(() {
      setState(() {});
    });
    runtime = context.read<ExtensionRuntimeManager>();
    executor = runtime.executor!;
    startFindingAnimeMatchAlgorithm();

    runtime.extensionServices.addListener(_onExtensionChange);
  } //TO UPDATE THE STATE OF THE PROGRESSESION OF EACH EXTENSION!!!

  void startGettingAnimeEpisodes() async {
    isSearching = false;
    isGettingEpisodes = true;
    episodeList = await executor!.getAnimeEpisodeList(matchedAnime!.url);

    print("found ${episodeList.length} episodes for ${matchedAnime!.name} ");

    //here is where we get the episode list

    itemCount = episodeList.length;

    int remaining = itemCount - firstTabCount;
    int otherTabs = (remaining / eachItemForTab).ceil();
    tabCount = 1 + (remaining > 0 ? otherTabs : 0);

    tabItemCounts = [];
    if (itemCount <= firstTabCount) {
      tabItemCounts.add(itemCount);
    } else {
      tabItemCounts.add(firstTabCount);
      for (int i = 0; i < otherTabs; i++) {
        int start = firstTabCount + i * eachItemForTab + 1;
        int end = start + eachItemForTab - 1;
        if (end > itemCount) end = itemCount;
        tabItemCounts.add(end - start + 1);
      }
    }

    labels = [];
    if (itemCount <= firstTabCount) {
      labels.add("1 - $itemCount");
    } else {
      labels.add("1 - $firstTabCount");
      for (int i = 0; i < otherTabs; i++) {
        int start = firstTabCount + i * eachItemForTab + 1;
        int end = start + eachItemForTab - 1;
        if (end > itemCount) end = itemCount;
        labels.add("$start - $end");
      }
    }
    if (mounted) {
      if (_tabController.length != tabCount) {
        _tabController.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
        _tabController.animation?.addListener(() {
          setState(() {}); // fires DURING swipe
        });
      }
      setState(() {
        isGettingEpisodes = false;
      });
    }
  }

  void startFindingAnimeMatchAlgorithm() async {
    matchedAnime = null;
    isSearching = true;
    isGettingEpisodes = false;

    if (runtime.extensionServices.mainExtension == null) {
      print("ERROR: there is no main extension");
      return;
    }

    final title =
        runtime.extensionServices.mainExtension?.anilistPreferedTitle!
                .toLowerCase() ==
            "english"
        ? widget.anime.media.title.english ??
              widget.anime.media.title.romaji ??
              widget.anime.media.title.native
        : runtime.extensionServices.mainExtension?.anilistPreferedTitle!
                  .toLowerCase() ==
              "romaji"
        ? widget.anime.media.title.romaji ??
              widget.anime.media.title.english ??
              widget.anime.media.title.native
        : "";

    if (title == "") {
      print("ERROR: title is empty");
      return;
    }

    try {
      //final searchResults = await currentExtension!.search(title);

      final searchResults = await executor!.searchAnime(title!);
      if (searchResults.isEmpty) {
        print(
          "ERROR: found 0 entries from searching \"${title}\" with extension \"${runtime.extensionServices.mainExtension!.name}\"",
        );
        return;
      }
      //INFO: fallback matching system
      matchedAnime = searchResults[0];

      // Find the best match
      MetiaAnime? bestMatch;
      double bestScore = 0;

      // Clean and normalize titles for comparison
      String normalizeTitle(String title) {
        return title
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final normalizedSearchTitle = normalizeTitle(title);
      final searchWords = normalizedSearchTitle.split(' ');

      for (MetiaAnime anime in searchResults) {
        final animeTitle = anime.name.toString();
        final normalizedAnimeTitle = normalizeTitle(animeTitle);

        if (normalizedAnimeTitle.isEmpty) continue;

        double score = 0;

        // Exact match
        if (normalizedAnimeTitle == normalizedSearchTitle) {
          score = 1.0;
        }
        // Contains match
        else if (normalizedAnimeTitle.contains(normalizedSearchTitle) ||
            normalizedSearchTitle.contains(normalizedAnimeTitle)) {
          score = 0.8;
        }
        // Word match
        else {
          final animeWords = normalizedAnimeTitle.split(' ');
          int matchingWords = 0;

          for (var word in searchWords) {
            if (animeWords.contains(word)) {
              matchingWords++;
            }
          }

          if (matchingWords > 0) {
            score = matchingWords / max(searchWords.length, animeWords.length);
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = anime;
        }
      }

      if (bestMatch != null && bestScore >= 0.5) {
        matchedAnime = bestMatch;
      } else {
        matchedAnime = searchResults[0];
      }
    } catch (e) {
      print("Error finding matching anime: $e");
    }
    isGettingEpisodes = true;
    startGettingAnimeEpisodes();
    //await prefs.setString(key, jsonEncode(bestMatch));

    print(
      "INFO: found this title \"${matchedAnime!.name}\" to be the best match ",
    );

    setState(() {
      //foundTitle = clossestAnime == null ? " " : clossestAnime["title"];
    });
  }

  void _onExtensionChange() {
    if (mounted) {
      setState(() {});
    }
    startFindingAnimeMatchAlgorithm();
  }

  void watchAnime(String url) {
    bool isLoading = true;
    List<StreamingData> streamingDatas = [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Run once
            if (isLoading) {
              executor!.getEpisodeStreamData(url).then((value) {
                setState(() {
                  streamingDatas = value;
                  isLoading = false;
                });
              });
            }

            return Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Text(
                          "Available Streams:",
                          style: TextStyle(
                            //color: MyColors.appbarTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.5,
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemCount: streamingDatas.length,
                            itemBuilder: (context, index) {
                              final streamingData = streamingDatas[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: scheme.onSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                width: double.infinity,
                                height: 60,
                                padding: const EdgeInsets.only(
                                  right: 12,
                                  left: 12,
                                ),

                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${streamingData.name.toUpperCase()} - ${streamingData.isSub ? "Sub" : "Dub"}",
                                      style: const TextStyle(
                                        //color: MyColors.appbarTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.5,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        //download button
                                        IconButton(
                                          onPressed: () {
                                            debugPrint("download started!");
                                          },
                                          icon: const Icon(
                                            Icons.download,
                                            //color: MyColors.appbarTextColor,
                                          ),
                                        ),
                                        //watch button
                                        IconButton(
                                          onPressed: () async {
                                            // Navigator.of(
                                            //   contextt,
                                            // ).pop("setState");
                                            // final result = await Navigator.push(
                                            //   context,
                                            //   MaterialPageRoute(
                                            //     builder: (context) => PlayerPage(
                                            //       episodeList: episodeList,
                                            //       currentExtension:
                                            //           currentExtension,
                                            //       episodeCount:
                                            //           episodeList.length,
                                            //       extensionEpisodeData:
                                            //           episodeList[episodeIndex],
                                            //       episodeNumber: episodeIndex + 1,
                                            //       extensionStreamData:
                                            //           snapshot.data?[index],
                                            //       anilistData: animeData,
                                            //     ),
                                            //   ),
                                            // );
                                            // if (result == "setState") {
                                            //   onDone();
                                            // }
                                          },
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            //color: MyColors.appbarTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    runtime.extensionServices.removeListener(_onExtensionChange);
  }

  @override
  Widget build(BuildContext context) {
    currentExtensions = runtime.extensionServices.currentExtensions;
    return Scaffold(
      body: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (nestedContext, innerBoxIsScrolled) => [
          buildAnimeInfo(),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
              nestedContext,
            ),
            sliver: buildExtensionInfo(),
          ),
        ],
        body: buildBody(),
      ),
    );
  }

  Widget buildStatus(String text, bool activeProgression) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 100),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20),
        activeProgression
            ? CircularProgressIndicator(color: Colors.orange)
            : Container(),
      ],
    );
  }

  Widget buildEpisodeList() {
    return Transform.translate(
      offset: Offset(0, 179),
      child: TabBarView(
        controller: _tabController,
        children: List.generate(tabCount, (tabIndex) {
          bool isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          EdgeInsetsGeometry padding = EdgeInsets.only(
            left: (isLandscape ? 20 : 0) + 12,
            right: (isLandscape ? 20 : 0) + 12,
            top: 12,
          );
          int count = tabItemCounts[tabIndex];
          int startIndex = (tabIndex == 0)
              ? 0
              : firstTabCount + (tabIndex - 1) * eachItemForTab;
          return count == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 90.0),
                    child: Text(
                      // "Anime Has \nNo Episodes Yet!",
                      "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: padding,
                  child: ListView.separated(
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      int episodeIndex = startIndex + index;
                      return buildAnimeEpisode(
                        episodeIndex,
                        (widget.anime.progress ?? 0) == episodeIndex,
                        (widget.anime.progress ?? 0) > episodeIndex,
                        episodeList[episodeIndex],
                        matchedAnime!.name,
                      );
                    },
                    itemCount: count,
                  ),
                );
        }),
      ),
    );
  }

  Widget buildBody() {
    Widget body = Container();

    if (isSearching) {
      body = buildStatus("Searching...", true);
    } else if (isGettingEpisodes) {
      body = buildStatus("Getting Anime Episodes...", true);
    } else {
      body = episodeList.isEmpty
          ? buildStatus("Anime Has \nNo Episodes Yet!", false)
          : buildEpisodeList();
    }

    return body;
  }

  Widget buildAnimeEpisode(
    int index,
    bool current,
    bool seen,
    MetiaEpisode episode,
    String title,
  ) {
    EpisodeDataService episodeDataService = Provider.of<EpisodeDataService>(
      context,
    );
    List<EpisodeData> currentEpisodes = episodeDataService.currentEpisodeDatas;

    bool hasEpisodeData =
        episodeDataService.getEpisodeDataOf(
          widget.anime.media.id,
          runtime.extensionServices.mainExtension!.id,
          index,
        ) !=
        null;
    double? percentage = 0; //INFO: out of 100 !!!!
    EpisodeData? epData;
    if (hasEpisodeData) {
      epData = episodeDataService.getEpisodeDataOf(
        widget.anime.media.id,
        runtime.extensionServices.mainExtension!.id,
        index,
      );
      percentage = (epData!.progress! / epData.total!) * 100;
    }

    //colors declarations!!
    final curretnBackgroundColor = Provider.of<ThemeProvider>(context).scheme.onPrimaryFixedVariant;
    final backgroundColor = Provider.of<ThemeProvider>(context).scheme.onSecondary;
    final progressBarColor = Provider.of<ThemeProvider>(context).scheme.secondary;

    return GestureDetector(
      onTapUp: (details) {
        watchAnime(episodeList[index].url);
      },
      child: Container(
        width: double.infinity,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  color: backgroundColor, // background bar
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: percentage / 100, // from 0.0 to 1.0
                      child: Container(
                        color: progressBarColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Container(
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: current
                    ? curretnBackgroundColor
                    : backgroundColor,
              ),
            ),
            Opacity(
              opacity: seen ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 100,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              errorWidget: (context, url, error) {
                                return Container();
                              },
                              imageUrl: episode.poster,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: SizedBox(
                            height: 100,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    episode.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    episode.isDub && episode.isSub
                                        ? "Sub | Dub"
                                        : episode.isSub
                                        ? "Sub"
                                        : episode.isDub
                                        ? "Dub"
                                        : "not specified",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (seen)
              const Positioned(
                left: 4,
                child: SizedBox(
                  height: 100,
                  width:
                      177.78, // This is 100 * (16/9) to match the AspectRatio
                  child: Center(
                    child: Icon(Icons.check, size: 60, color: Colors.white),
                  ),
                ),
              ),
            SizedBox(
              height: 100,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Transform.translate(
                  offset: const Offset(0, 4.1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: current
                          ? curretnBackgroundColor
                          : backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExtensionInfo() {
    return SliverAppBar(
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
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        tooltip: "Select Extension",
                        onSelected: (String id) async {
                          await runtime.extensionServices.setMainExtension(
                            currentExtensions!
                                .where((e) => e.id == int.parse(id))
                                .first,
                          );
                        },
                        itemBuilder: (BuildContext context) {
                          //TODO: load available extensions here
                          return currentExtensions!.isNotEmpty
                              ? currentExtensions!.map((e) {
                                  return PopupMenuItem<String>(
                                    value: "${e.id}",
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: e.iconUrl!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            e.name!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        e.isMain
                                            ? Icon(Icons.check, size: 18)
                                            : Container(),
                                      ],
                                    ),
                                  );
                                }).toList()
                              : [
                                  PopupMenuItem<String>(
                                    value: "no_extension",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.extension,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "no Extension is installed!",
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
                                child:
                                    runtime.extensionServices.mainExtension ==
                                        null
                                    ? Icon(
                                        Icons.extension,
                                        color: scheme.primary,
                                      )
                                    : SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: runtime
                                                .extensionServices
                                                .mainExtension!
                                                .iconUrl!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: scheme.primary),
                          ],
                        ),
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
                          runtime.extensionServices.mainExtension != null
                              ? matchedAnime != null
                                    ? matchedAnime!.name
                                    : "Searching..."
                              : "No Extension Selected",
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
                          ? widget.anime.media.episodes == widget.anime.progress
                                ? "FINISHED"
                                : "CONTINUE EPISODE ${(widget.anime.progress ?? 0) + 1}"
                          : "NULL",
                      style: TextStyle(
                        color: runtime.ready.value ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon:
                        widget.anime.media.episodes != null &&
                            widget.anime.media.episodes != widget.anime.progress
                        ? const Icon(Icons.play_arrow_outlined, size: 20)
                        : const SizedBox(),
                    onPressed: () async {},
                  ),
                ),
                const SizedBox(height: 10),
                //Tab bar builder
                TabBar(
                  controller: _tabController,
                  tabAlignment: TabAlignment.start,
                  labelPadding: EdgeInsets.zero,
                  isScrollable: true,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  onTap: (value) {
                    setState(() {});
                  },
                  tabs: List.generate(labels.length, (i) {
                    final double value =
                        _tabController.animation?.value ??
                        _tabController.index.toDouble();

                    final double distance = (value - i).abs();
                    final double t = (1.0 - distance).clamp(0.0, 1.0);

                    final Color background = Color.lerp(
                      Colors.transparent,
                      Colors.white,
                      t,
                    )!;

                    final Color textColor = Color.lerp(
                      const Color(0xFF9A989B),
                      Colors.deepPurpleAccent,
                      t,
                    )!;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: background,
                        border: Border.all(color: Colors.deepPurple),
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
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
      expandedHeight: (MediaQuery.of(context).size.height) * 0.5,
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
