import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/user/profile.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:metia/widgets/library_anime_card.dart';
import 'package:provider/provider.dart';
import 'package:metia/widgets/color_transition_tab_bar.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  int _previousLibraryLength = 0;
  int _savedTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController(int newLength) {
    if (newLength != _previousLibraryLength) {
      _savedTabIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);

      if (_savedTabIndex < newLength) {
        _tabController.index = _savedTabIndex;
      } else if (newLength > 0) {
        _tabController.index = newLength - 1;
      }

      _previousLibraryLength = newLength;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final library = userProvider.user.userLibrary.library;

    if (!isLoggedIn) {
      return const Center(child: Text('Please log in to view your library'));
    }

    if (library.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _updateTabController(library.length);

    return Column(
      children: [
        _buildTabBar(userProvider.user),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: library.map((libraryEntry) {
                      return _buildTabContent(libraryEntry);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(Profile user) {
    return ColorTransitionTabBar(
      tabs: user.userLibrary.library.map((e) {
        return "${e.name} (${e.entries.length})";
      }).toList(),
      controller: _tabController,
      tabColors: user.userLibrary.library.map((e) {
        Color color = Colors.black;

        if (e.color == Colors.white) {
          color = Theme.of(context).colorScheme.onSecondaryContainer;
        } else if (e.color == Colors.green) {
          color = Theme.of(context).colorScheme.onTertiaryContainer;
        } else if (e.color == Colors.orange) {
          color = Theme.of(context).colorScheme.error;
        }

        return color;
      }).toList(),
    );
  }

  Widget _buildTabContent(dynamic libraryEntry) {
    final crossAxisCount = Tools.getResponsiveCrossAxisVal(
      MediaQuery.of(context).size.width,
      itemWidth: 135,
    );

    if (Platform.isAndroid) {
      return RefreshIndicator.adaptive(
        onRefresh: () => Provider.of<UserProvider>(context, listen: false).reloadUserData(),
        child: GridView.builder(
          key: PageStorageKey('library_grid_${libraryEntry.name}'),
          cacheExtent: 500,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 268,
            childAspectRatio: 0.7,
          ),
          itemCount: libraryEntry.entries.length,
          itemBuilder: (context, index) {
            final MediaListEntry anime = libraryEntry.entries[index];
            return AnimeCard(
              key: ValueKey('${anime.id}_${libraryEntry.name}'),
              context: context,
              index: index,
              tabName: anime.status,
              anime: anime,
              onLibraryChanged: () {},
            );
          },
        ),
      );
    }

    return CustomScrollView(
      cacheExtent: 500,
      key: PageStorageKey('library_scroll_${libraryEntry.name}'),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Provider.of<UserProvider>(context, listen: false).reloadUserData();
          },
        ),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 268,
            childAspectRatio: 0.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final MediaListEntry anime = libraryEntry.entries[index];
              return AnimeCard(
                key: ValueKey('${anime.id}_${libraryEntry.name}'),
                context: context,
                index: index,
                tabName: anime.status,
                anime: anime,
                onLibraryChanged: () {},
              );
            },
            childCount: libraryEntry.entries.length,
          ),
        ),
      ],
    );
  }
}