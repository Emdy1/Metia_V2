import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metia/anilist/anime.dart';
import 'package:metia/data/user/profile.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/screens/anime_page.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:metia/widgets/explorer_anime_card.dart';
import 'package:metia/widgets/library_anime_card.dart';
import 'package:provider/provider.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late Profile user;
  late double itemWidth;
  late bool isLoggedIn;
  late Profile defaultUser;

  bool isLoadingExplorerContent = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    isLoadingExplorerContent = isLoggedIn
        ? Provider.of<UserProvider>(context, listen: false).isLoadingExplorerContent
        : Provider.of<UserProvider>(context, listen: false).isLoadingDefaultExplorerContent;
    defaultUser = Profile(
      name: "",
      avatarLink: "",
      bannerImage: "",
      id: 0,
      userLibrary: UserLibrary(library: []),
      statistics: Statistics(),
      userActivityPage: ActivityPage(
        pageInfo: PageInfo(total: 0, perPage: 0, currentPage: 0, lastPage: 0, hasNextPage: false),
        activities: [],
      ),
      userLists: [],
      explorerContent: [[], [], [], [], [], []],
    );
  }

  void searchPressed() {
    String keyword = "bleach";
    List<Media> animes = [];
    bool isLoading = true;
    final TextEditingController searchController = TextEditingController(text: keyword);
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
                    final value = await anilistSearch(keyword); //TODO: change with anilist search api
                    setState(() {
                      animes = value;
                      isLoading = false;
                    });
                  });
                }

                Future<void> search(String query) async {
                  setState(() => isLoading = true);
                  final value = await anilistSearch(query); //TODO: change with anilist search api
                  setState(() {
                    animes = value;
                    isLoading = false;
                  });
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search Anime',
                          hintText: 'Enter anime name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary))
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                    boxConstraints.maxWidth,
                                    itemWidth: 135,
                                  ),
                                  mainAxisExtent: 268,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: animes.length,
                                itemBuilder: (context, index) {
                                  final anime = animes[index];
                                  final poster = anime.coverImage.large;
                                  final name = anime.title.english ?? anime.title.romaji ?? anime.title.native;

                                  return GestureDetector(
                                    onTap: () async {
                                      Provider.of<ThemeProvider>(context, listen: false).setSeed(anime.coverImage.color);

                                      await Navigator.of(context).push(
                                        CustomPageRoute(
                                          builder: (context) => AnimePage(
                                            anime: MediaListEntry(id: 0, status: "", media: anime),
                                          ),
                                        ),
                                      );
                                      Provider.of<ThemeProvider>(
                                        context,
                                        listen: false,
                                      ).setSeed(Color.fromARGB(255, 72, 255, 0));

                                      //TODO: Navigate to the aniem page with the appropriate data!
                                    },
                                    child: Card(
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: 135,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  SizedBox(
                                                    height: 183,
                                                    width: 135,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: CachedNetworkImage(
                                                        imageUrl: poster,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => const Center(
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        name!,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
                                                        ),
                                                        textAlign: TextAlign.center,
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
  Widget build(BuildContext context) {
    isLoadingExplorerContent = isLoggedIn
        ? Provider.of<UserProvider>(context, listen: false).isLoadingExplorerContent
        : Provider.of<UserProvider>(context, listen: false).isLoadingDefaultExplorerContent;
    defaultUser.explorerContent = Provider.of<UserProvider>(context).defaultExplorerContent;
    itemWidth =
        MediaQuery.of(context).size.width /
        Tools.getResponsiveCrossAxisVal(MediaQuery.of(context).size.width, itemWidth: 135);
    user = isLoggedIn ? Provider.of<UserProvider>(context).user : defaultUser;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Search"),
        icon: Icon(Icons.search),
        onPressed: searchPressed,
      ),
      body: isLoadingExplorerContent
          ? _buildLoadingExplorerContnet()
          //: _buildLoadingExplorerContnet(),
          : _buidlExplorerBody(),
    );
  }

  _buildLoadingExplorerContnet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            "Loading Explorer...",
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Theme.of(context).colorScheme.tertiary),
          ),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  _buidlExplorerBody() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: !(Platform.isIOS || Platform.isMacOS)
          ? RefreshIndicator(
              onRefresh: () async {
                await Provider.of<UserProvider>(context, listen: false).reloadUserData();
              },
              child: CustomScrollView(
                slivers: [
                  if (Platform.isIOS || Platform.isMacOS)
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await Provider.of<UserProvider>(context, listen: false).reloadUserData();
                      },
                    ),
                  _buildSection(user.explorerContent[0], "Trending Now"),
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildSection(user.explorerContent[1], "Popular This Season"),
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildSection(user.explorerContent[2], "Upcoming This Season"),
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildSection(user.explorerContent[3], "All Time Popular"),
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Text(
                      "Top 100 Anime",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildTop100AnimeSection(user.explorerContent[4]),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                if (Platform.isIOS || Platform.isMacOS)
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      await Provider.of<UserProvider>(context, listen: false).reloadUserData();
                    },
                  ),
                _buildSection(user.explorerContent[0], "Trending Now"),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildSection(user.explorerContent[1], "Popular This Season"),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildSection(user.explorerContent[2], "Upcoming This Season"),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildSection(user.explorerContent[3], "All Time Popular"),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Text(
                    "Top 100 Anime",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16)),

                _buildTop100AnimeSection(user.explorerContent[4]),
              ],
            ),
    );
  }

  _buildTop100AnimeSection(List<Media> entries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: entries.length, (context, index) {
        return _animeCardLandscape(entries[index]);
      }),
    );
  }

  _animeCardLandscape(Media media) {
    String title = media.title.english ?? media.title.romaji ?? media.title.native ?? "NO TITLE";
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: media.coverImage.large,
            height: 100,
            width: 75,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(width: 75, height: 100, color: Colors.grey[300]),
            errorWidget: (context, url, error) => Container(width: 75, height: 100, color: Colors.grey),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: SizedBox(
              height: 100,
              child: AspectRatio(
                aspectRatio: 1900 / 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    media.bannerImage != null
                        ? CachedNetworkImage(
                            imageUrl: media.bannerImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => Container(color: Colors.grey),
                          )
                        : Container(color: media.color),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent.withAlpha(50), Colors.black.withAlpha(100)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: ColorScheme.fromSeed(seedColor: media.color ?? Colors.blue).onInverseSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildSection(List<Media> entries, String headLine) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headLine,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 268,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 0),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Media media = entries[index];
                bool alreadyInLibrary = false;
                String listName = "";
                for (var group in user.userLibrary.library) {
                  for (var i = 0; i < group.entries.length; i++) {
                    if (group.entries[i].media.id == media.id) {
                      alreadyInLibrary = true;
                      listName = group.name;
                    }
                  }
                }

                return SizedBox(
                  width: itemWidth + ((MediaQuery.of(context).orientation == Orientation.landscape) ? -12.4 : -3.5),
                  child: ExplorerAnimeCard(
                    alreadyInLibrary: alreadyInLibrary,
                    onLibraryChanged: () {},
                    context: context,
                    anime: media,
                    index: index,
                    listName: listName,
                  ),
                );
              },
              itemCount: entries.length,
            ),
          ),
        ],
      ),
    );
  }
}
