import 'package:flutter/material.dart';
import 'package:metia/anilist/anime.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:metia/widgets/explorer_anime_card.dart';
import 'package:provider/provider.dart';

class AnimeSearchSheet extends StatefulWidget {
  const AnimeSearchSheet({super.key});

  @override
  State<AnimeSearchSheet> createState() => _AnimeSearchSheetState();
}

class _AnimeSearchSheetState extends State<AnimeSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = "bleach";

  @override
  void initState() {
    super.initState();
    // Start initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).searchAnime(_keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return SizedBox(
      height: isLandscape
          ? MediaQuery.of(context).size.height
          : MediaQuery.of(context).size.height * 0.563,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search Anime',
                        hintText: 'Enter anime name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _keyword = value.trim();
                          userProvider.searchAnime(_keyword);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: userProvider.isSearching
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary))
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                  boxConstraints.maxWidth,
                                  itemWidth: 135,
                                ),
                                mainAxisExtent: 268,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: userProvider.searchResults.length,
                              itemBuilder: (context, index) {
                                Media media =
                                    userProvider.searchResults[index];
                                bool alreadyInLibrary =
                                    userProvider.isMediaInLibrary(media.id);
                                String listName = "";
                                if (alreadyInLibrary) {
                                  for (var group
                                      in userProvider.user.userLibrary.library) {
                                    for (var i = 0;
                                        i < group.entries.length;
                                        i++) {
                                      if (group.entries[i].media.id ==
                                          media.id) {
                                        listName = group.name;
                                      }
                                    }
                                  }
                                }

                                return SizedBox(
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
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
