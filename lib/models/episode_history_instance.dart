import 'package:isar/isar.dart';
import 'package:metia/models/anime_database.dart';

part 'episode_history_instance.g.dart';

@Collection()
class EpisodeHistoryInstance {
  Id id = Isar.autoIncrement;
  MetiaEpisode? episode;
  MetiaAnime? anime;
  String? title;
  int? episodeNumber;
  int? anilistMeidaId;
  int? extensionId;
  bool? seen;
  List<MetiaEpisode>? parentList;
}
