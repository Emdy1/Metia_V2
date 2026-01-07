import 'package:flutter/material.dart';
import 'package:metia/anilist/anime.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/js_core/script_executor.dart';
import 'package:metia/models/anime_database.dart';
import 'package:metia/models/anime_database_service.dart';
import 'package:metia/models/episode_history_instance.dart';
import 'package:metia/models/episode_history_service.dart';
import 'package:metia/screens/player_page.dart';
import 'package:metia/widgets/custom_widgets.dart'; 
import 'package:metia/models/logger.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<EpisodeHistoryInstance> history = [];
  late ExtensionRuntimeManager runtime;
  late AnimeDatabaseService animeDatabaseService;
  late ScriptExecutor executor;
  late ColorScheme scheme;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scheme = Theme.of(context).colorScheme;
    runtime = context.read<ExtensionRuntimeManager>();
    executor = runtime.executor!;
  }

  void seetState() {
    setState(() {});
  }

  void watchAnime(String url, MetiaEpisode episode, int episodeIndex, String animeTitle) async {
    bool isLoading = true;
    List<StreamingData> streamingDatas = [];

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        return SizedBox(
          height: isLandscape ? MediaQuery.of(context).size.height * 1 : MediaQuery.of(context).size.height * 0.563,
          child: StatefulBuilder(
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
                    ? Center(child: CircularProgressIndicator(color: scheme.tertiary))
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
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                                  padding: const EdgeInsets.only(right: 12, left: 12),

                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              Logger.log("download started!");
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
                                                  builder: (context) => PlayerPage(
                                                    episodeList: history[index].parentList!,
                                                    animeStreamingData: streamingData,
                                                    mediaListEntry: MediaListEntry(
                                                      id: 0,
                                                      status: "CURRENT",
                                                      media: Media.fromJson({
                                                        "id": history[index].anilistMediaId!,
                                                        "title": {"english": animeTitle},
                                                      }),
                                                    ),
                                                    animeData: history[index].anime!,
                                                    episodeData: history[index].parentList!
                                                        .where((element) => element.url == url)
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
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    history = Provider.of<EpisodeHistoryService>(context, listen: true).currentEpisodeHistory;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "History",
          style: TextStyle(fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 12, right: 12, top: 6),
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final episodeHistoryInstance = history[index];
            return EpisodeItem(
              key: ValueKey('episode_$index'),
              index: episodeHistoryInstance.episodeNumber!, // Episode Index, starts from 0
              animeId: episodeHistoryInstance.anilistMediaId!, // Anilist Media Id
              extensionId: episodeHistoryInstance.extensionId!, // Extension Id
              current: false, // is current episode, should be false by default in this scenario
              seen: episodeHistoryInstance.seen!, // has been seen, should be false by default in this scenario
              episode: episodeHistoryInstance.episode!, // MetiaEpisode object
              animeTitle: episodeHistoryInstance.title!, // Anime Title
              onTap: () {
                watchAnime(
                  episodeHistoryInstance.episode!.url,
                  episodeHistoryInstance.episode!,
                  episodeHistoryInstance.episodeNumber!,
                  episodeHistoryInstance.title!,
                );
              }, // onTap function
            );
          },
          itemCount: history.length,
        ),
      ),
    );
  }
}
