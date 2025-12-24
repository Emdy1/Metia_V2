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
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/screens/extensions_page.dart';
import 'package:metia/screens/player_page.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:metia/widgets/custom_tab.dart';
import 'package:metia/widgets/custom_widgets.dart';
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
  late final AnimeDatabaseService animeDatabaseService;
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
  bool lastExpanded = false;

  bool isSearching = true;
  bool isGettingEpisodes = false;

  late TabController _tabController;

  //this is garbage but i got no other solution
  int progress = 0;

  @override
  void initState() {
    super.initState();
    lastExpanded = false;

    runtime = context.read<ExtensionRuntimeManager>();
    executor = runtime.executor!;

    animeDatabaseService = context.read<AnimeDatabaseService>();

    _tabController = TabController(length: 1, vsync: this);

    //once the matched anime has been updated by correctMatchedAnime function update the UI
    animeDatabaseService.addListener(_animeDbListener);
    //TO UPDATE THE STATE OF THE PROGRESSESION OF EACH EXTENSION!!!
    runtime.extensionServices.addListener(_onExtensionChange);

    if (runtime.extensionServices.mainExtension != null)
      startFindingAnimeMatchAlgorithm();
  }

  void _animeDbListener() {
    if (!mounted) return;
    startFindingAnimeMatchAlgorithm();
  }

  void _onExtensionChange() {
    if (mounted) {
      setState(() {});
    }
    startFindingAnimeMatchAlgorithm();
  }

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
      }
      setState(() {
        isGettingEpisodes = false;
      });
    }
  }

  void startFindingAnimeMatchAlgorithm() async {
    if (animeDatabaseService.existsInDatabse(
      widget.anime.media.id,
      runtime.extensionServices.mainExtension!.id,
    )) {
      matchedAnime = animeDatabaseService
          .getAnimeDataOf(
            widget.anime.media.id,
            runtime.extensionServices.mainExtension!.id,
          )!
          .matchedAnime;
      isGettingEpisodes = true;
      startGettingAnimeEpisodes();
      //await prefs.setString(key, jsonEncode(bestMatch));

      print(
        "INFO: found this title \"${matchedAnime!.name}\" to be the best match ",
      );

      setState(() {
        //foundTitle = clossestAnime == null ? " " : clossestAnime["title"];
      });
      return;
    }

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
            .toLowerCase() // lowercase
            .replaceAll(RegExp(r'\s+'), ' ') // normalize multiple spaces
            .trim(); // remove leading/trailing spaces
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

    animeDatabaseService.addAnimeDatabases(
      matchedAnime!,
      widget.anime.media.id,
      runtime.extensionServices.mainExtension!.id,
    );

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

  void seetState() {
    setState(() {});
  }

  void watchAnime(String url) async {
    bool isLoading = true;
    List<StreamingData> streamingDatas = [];

    await showModalBottomSheet(
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
                  ? Center(
                      child: CircularProgressIndicator(color: scheme.tertiary),
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
                                            // Navigator.of(context).pop();
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PlayerPage(
                                                      episodeList: episodeList,
                                                      animeStreamingData:
                                                          streamingData,
                                                      mediaListEntry:
                                                          widget.anime,
                                                      animeData: matchedAnime!,
                                                      episodeData: episodeList
                                                          .where(
                                                            (element) =>
                                                                element.url ==
                                                                url,
                                                          )
                                                          .first,
                                                    ),
                                              ),
                                            );
                                            seetState();

                                            // Navigator.pop(context);
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
    setState(() {});
  }

  void correctMatchedAnime(String keyword) {
    List<MetiaAnime> animes = [];
    bool isLoading = true;
    final TextEditingController searchController = TextEditingController(
      text: keyword,
    );
    bool hasFetched = false; // run initial fetch once

    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      //isScrollControlled: true,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, boxConstraints) {
            return StatefulBuilder(
              builder: (context, setState) {
                // Initial fetch, only once
                if (!hasFetched) {
                  hasFetched = true;
                  Future.microtask(() async {
                    final value = await executor!.searchAnime(keyword);
                    setState(() {
                      animes = value;
                      isLoading = false;
                    });
                  });
                }

                Future<void> search(String query) async {
                  setState(() => isLoading = true);
                  final value = await executor!.searchAnime(query);
                  setState(() {
                    animes = value;
                    isLoading = false;
                  });
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search Anime',
                          hintText: 'Enter anime name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            search(value.trim());
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          Tools.getResponsiveCrossAxisVal(
                                            boxConstraints.maxWidth,
                                            itemWidth: 135,
                                          ),
                                      mainAxisExtent: 268,
                                      childAspectRatio: 0.7,
                                    ),
                                itemCount: animes.length,
                                itemBuilder: (context, index) {
                                  final poster = animes[index].poster;
                                  final name = animes[index].name;

                                  return GestureDetector(
                                    onTap: () async {
                                      await animeDatabaseService
                                          .updateAnimeDatabases(
                                            animes[index],
                                            widget.anime.media.id,
                                            runtime
                                                .extensionServices
                                                .mainExtension!
                                                .id,
                                          );
                                      Navigator.of(context).pop();
                                    },
                                    child: Card(
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: 135,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  SizedBox(
                                                    height: 183,
                                                    width: 135,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl: poster,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => const Icon(
                                                              Icons.error,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        name,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .fontSize,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    runtime.extensionServices.removeListener(_onExtensionChange);
    animeDatabaseService.removeListener(_animeDbListener);
  }

  @override
  Widget build(BuildContext context) {
    currentExtensions = runtime.extensionServices.currentExtensions;

    List<MediaListGroup> userLIb = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user.userLibrary.library;
    for (var group in userLIb) {
      if (group.entries
              .where((element) => element.media.id == widget.anime.media.id)
              .length >
          0) {
        progress = group.entries
            .where((element) => element.media.id == widget.anime.media.id)
            .first
            .progress!;
      }
    }
    return Scaffold(
      body: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (nestedContext, innerBoxIsScrolled) => [
          buildAnimeInfo(),
          buildExtensionInfo(),
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
          style: TextStyle(
            color: scheme.tertiary,
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 20),
        activeProgression
            ? CircularProgressIndicator(color: scheme.tertiary)
            : Container(),
      ],
    );
  }

  Widget buildEpisodeList() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(tabCount, (tabIndex) {
        bool isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        EdgeInsetsGeometry padding = EdgeInsets.only(
          left: (isLandscape ? 20 : 0) + 12,
          right: (isLandscape ? 20 : 0) + 12,
        );
        int count = tabItemCounts[tabIndex];
        int startIndex = (tabIndex == 0)
            ? 0
            : firstTabCount + (tabIndex - 1) * eachItemForTab;

        return count == 0
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 90.0),
                  child: Text(
                    "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: padding,
                child: ListView.separated(
                  // OPTIMIZATION: Add itemExtent for better performance
                  //itemExtent: 116, // 108 + 8 separator
                  //cacheExtent: 500, // Preload nearby items
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    bool seen = false;
                    int episodeIndex = startIndex + index;

                    // OPTIMIZATION: Use the new optimized widget
                    return EpisodeItem(
                      key: ValueKey('episode_$episodeIndex'),
                      index: episodeIndex,
                      animeId: widget.anime.media.id,
                      extensionId: runtime.extensionServices.mainExtension!.id,
                      current: (progress ?? 0) == episodeIndex,
                      //seen: true,
                      seen: (progress ?? 0) > episodeIndex,
                      episode: episodeList[episodeIndex],
                      title: matchedAnime!.name,
                      scheme: scheme,
                      onTap: () => watchAnime(episodeList[episodeIndex].url),
                    );
                  },
                  itemCount: count,
                ),
              );
      }),
    );
  }

  Widget buildBody() {
    Widget body = Container();

    if (runtime.extensionServices.currentExtensions.isEmpty) {
      body = buildStatus("No Extension Installed!", false);
    } else if (runtime.extensionServices.mainExtension == null) {
      body = buildStatus("No Extension Selcted!", false);
    } else if (isSearching) {
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
    final episodeDataService = context.watch<EpisodeDataService>();

    bool hasEpisodeData =
        episodeDataService.getEpisodeDataOf(
          widget.anime.media.id,
          runtime.extensionServices.mainExtension!.id,
          index,
        ) !=
        null;

    double percentage = 0; // out of 100
    EpisodeData? epData;

    if (hasEpisodeData) {
      epData = episodeDataService.getEpisodeDataOf(
        widget.anime.media.id,
        runtime.extensionServices.mainExtension!.id,
        index,
      );
      percentage = (epData!.progress! / epData.total!) * 100;
    }

    // ===== Material 3 colors =====
    final currentBackgroundColor = scheme.primaryContainer;
    final backgroundColor = scheme.surfaceContainerHighest;

    final currentTextColor = scheme.onPrimaryContainer;
    final normalTextColor = scheme.onSurface;
    final secondaryTextColor = scheme.onSurfaceVariant;

    final progressBarColor = current ? scheme.primary : scheme.secondary;

    return GestureDetector(
      onTapUp: (_) {
        watchAnime(episodeList[index].url);
      },
      child: Container(
        width: double.infinity,
        height: 108,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          children: [
            // ===== Progress bar =====
            ClipRRect(
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
              opacity: seen ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      // Thumbnail
                      SizedBox(
                        height: 100,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: episode.poster,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(),
                            ),
                          ),
                        ),
                      ),

                      // Text content
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
                                    style: TextStyle(
                                      color: current
                                          ? currentTextColor
                                          : secondaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    episode.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: current
                                          ? currentTextColor
                                          : normalTextColor,
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Seen check =====
            if (seen)
              const Positioned(
                left: 4,
                child: SizedBox(
                  height: 100,
                  width: 177.78,
                  child: Center(
                    child: Icon(Icons.check, size: 60, color: Colors.white),
                  ),
                ),
              ),

            // ===== Episode number badge =====
            SizedBox(
              height: 100,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Transform.translate(
                  offset: const Offset(0, 4.1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: current ? currentBackgroundColor : backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: current ? currentTextColor : normalTextColor,
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
      //collapsedHeight: 179,
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
                          if (id == "no_extension") {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExtensionsPage(),
                              ),
                            );
                            return;
                          }
                          await runtime.extensionServices.setMainExtension(
                            currentExtensions!
                                .where((e) => e.id == int.parse(id))
                                .first,
                          );
                        },
                        itemBuilder: (BuildContext context) {
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
                                            "No Extension Installed!",
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
                    Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Found:",
                        style: TextStyle(
                          color: scheme.onSurface,
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
                              : runtime
                                    .extensionServices
                                    .currentExtensions
                                    .isEmpty
                              ? "No Extension Installed!"
                              : "No Extension Selceted!",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: scheme.tertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GestureDetector(
                        onTap: () async {
                          if (runtime.extensionServices.mainExtension == null ||
                              runtime
                                  .extensionServices
                                  .currentExtensions
                                  .isEmpty)
                            return;

                          final title =
                              runtime
                                      .extensionServices
                                      .mainExtension
                                      ?.anilistPreferedTitle!
                                      .toLowerCase() ==
                                  "english"
                              ? widget.anime.media.title.english ??
                                    widget.anime.media.title.romaji ??
                                    widget.anime.media.title.native
                              : runtime
                                        .extensionServices
                                        .mainExtension
                                        ?.anilistPreferedTitle!
                                        .toLowerCase() ==
                                    "romaji"
                              ? widget.anime.media.title.romaji ??
                                    widget.anime.media.title.english ??
                                    widget.anime.media.title.native
                              : "";

                          //correctMatchedAnime(title!);
                          await Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).reloadUserData();
                          setState(() {});
                        },
                        child: Text(
                          "Wrong?",
                          style: TextStyle(
                            color:
                                runtime.extensionServices.mainExtension ==
                                        null ||
                                    runtime
                                        .extensionServices
                                        .currentExtensions
                                        .isEmpty
                                ? scheme.onSurface.withOpacity(0.38)
                                : scheme.primary,
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
                      foregroundColor:
                          runtime.extensionServices.mainExtension == null ||
                              runtime
                                  .extensionServices
                                  .currentExtensions
                                  .isEmpty
                          ? scheme.onSurfaceVariant.withOpacity(0.38)
                          : scheme.primaryFixedDim,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color:
                              runtime.extensionServices.mainExtension == null ||
                                  runtime
                                      .extensionServices
                                      .currentExtensions
                                      .isEmpty
                              ? scheme.onSurfaceVariant.withOpacity(0.38)
                              : scheme.primaryFixedDim,
                        ),
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
                        color:
                            runtime.extensionServices.mainExtension == null ||
                                runtime
                                    .extensionServices
                                    .currentExtensions
                                    .isEmpty
                            ? scheme.onSurfaceVariant.withOpacity(0.38)
                            : scheme.primaryFixedDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon:
                        widget.anime.media.episodes != null &&
                            widget.anime.media.episodes != widget.anime.progress
                        ? const Icon(Icons.play_arrow_outlined, size: 20)
                        : const SizedBox(),
                    onPressed: () async {
                      if (runtime.extensionServices.mainExtension == null ||
                          runtime.extensionServices.currentExtensions.isEmpty) {
                        return;
                      }
                      watchAnime(
                        episodeList[widget.anime.progress ?? 0].url,
                      ); // i used ?? 0 to guard against referencing a null progress if the user has never watched that anime
                    },
                  ),
                ),
                const SizedBox(height: 10),
                //Tab bar builder
                StatefulBuilder(
                  builder: (context, safeSetState) {
                    return TabBar(
                      controller: _tabController,
                      tabAlignment: TabAlignment.start,
                      labelPadding: EdgeInsets.zero,
                      isScrollable: true,
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      onTap: (value) {
                        safeSetState(() {});
                      },
                      tabs: List.generate(labels.length, (i) {
                        return CustomTab(
                          controller: _tabController,
                          scheme: scheme,
                          label: labels[i],
                          index: i,
                        );
                      }),
                    );
                  },
                ),
                // TabBar(
                //   controller: _tabController,
                //   tabAlignment: TabAlignment.start,
                //   labelPadding: EdgeInsets.zero,
                //   isScrollable: true,
                //   indicatorColor: Colors.transparent,
                //   dividerColor: Colors.transparent,
                //   onTap: (value) {
                //     setState(() {});
                //   },
                //   tabs: List.generate(labels.length, (i) {
                //     return CustomTab(
                //       controller: _tabController,
                //       scheme: scheme,
                //       label: labels[i],
                //       index: i,
                //     );
                //   }),
                // ),
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
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surface,
      pinned: true,
      title: StatefulBuilder(
        builder: (context, safeSetState) {
          scrollController.addListener(() {
            final expanded = isAppBarExpanded;
            if (expanded != lastExpanded) {
              lastExpanded = expanded;
              safeSetState(() {}); // Only rebuild when expansion state changes
            }
          });
          return AnimatedOpacity(
            opacity: isAppBarExpanded ? 1 : 0,
            duration: Duration(milliseconds: 100),
            child: Text(widget.anime.media.title.english ?? "No Title"),
          );
        },
      ),
      expandedHeight: (MediaQuery.of(context).size.height) * 0.5,
      //stretch: true,
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
                              Icon(
                                Icons.schedule,
                                color: scheme.primary,

                                size: 22,
                              ),
                              Text(
                                ' Episode $episode: $timeString',
                                style: TextStyle(
                                  color: scheme.primary,
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
                          // Title
                          Text(
                            widget.anime.media.title.english ?? "No Title",
                            style: TextStyle(
                              color: scheme
                                  .onBackground, // instead of Colors.white
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Genres
                          Text(
                            (widget.anime.media.genres ?? []).join(' • '),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant, // instead of grey
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Rating
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.anime.media.averageScore == null
                                    ? "0.0"
                                    : "${(widget.anime.media.averageScore! / 10).toStringAsFixed(1)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: scheme.tertiary, // highlight
                                ),
                              ),
                              Icon(
                                Icons.star,
                                color: scheme.tertiary,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Synopsis label
                          Text(
                            "Synopsis",
                            style: TextStyle(
                              color: scheme
                                  .onBackground, // instead of Colors.white
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Description
                          Text(
                            widget.anime.media.description?.replaceAll(
                                  RegExp(r'<[^>]*>'),
                                  '',
                                ) ??
                                "",
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              height: 1.1,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant, // instead of grey
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
