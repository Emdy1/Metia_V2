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
  DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'episodeNumber': episodeNumber,
        'anilistMeidaId': anilistMeidaId,
        'extensionId': extensionId,
        'seen': seen,
        'episode': episode != null
            ? {
                'poster': episode!.poster,
                'name': episode!.name,
                'url': episode!.url,
                'isDub': episode!.isDub,
                'isSub': episode!.isSub,
              }
            : null,
        'anime': anime != null
            ? {
                'name': anime!.name,
                'length': anime!.length,
                'poster': anime!.poster,
                'url': anime!.url
              }
            : null,
        'lastModified': lastModified?.toIso8601String(),
      };

  EpisodeHistoryInstance fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? id;
    title = json['title'];
    episodeNumber = json['episodeNumber'];
    anilistMeidaId = json['anilistMeidaId'];
    extensionId = json['extensionId'];
    seen = json['seen'];
    if (json['episode'] != null) {
      episode = MetiaEpisode()
        ..poster = json['episode']['poster']
        ..name = json['episode']['name']
        ..url = json['episode']['url']
        ..isDub = json['episode']['isDub']
        ..isSub = json['episode']['isSub'];
    }
    if (json['anime'] != null) {
      anime = MetiaAnime()
        ..name = json['anime']['name']
        ..length = json['anime']['length']
        ..poster = json['anime']['poster']
        ..url = json['anime']['url'];
    }
    lastModified = json['lastModified'] != null
        ? DateTime.parse(json['lastModified'])
        : DateTime.now();
    return this;
  }
}
