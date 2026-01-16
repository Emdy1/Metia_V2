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
  int? anilistMediaId;
  int? extensionId;
  bool? seen;
  List<MetiaEpisode>? parentList;
  DateTime? lastModified;

  // Map<String, dynamic> toJson() => {
  //   'id': id,
  //   'title': title,
  //   'episodeNumber': episodeNumber,
  //   'anilistMediaId': anilistMediaId,
  //   'extensionId': extensionId,
  //   'seen': seen,
  //   'episode': episode != null
  //       ? {
  //           'poster': episode!.poster,
  //           'name': episode!.name,
  //           'url': episode!.url,
  //           'isDub': episode!.isDub,
  //           'isSub': episode!.isSub,
  //         }
  //       : null,
  //   'anime': anime != null
  //       ? {'name': anime!.name, 'length': anime!.length, 'poster': anime!.poster, 'url': anime!.url}
  //       : null,
  //   'lastModified': lastModified?.toIso8601String(),
  // };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'episodeNumber': episodeNumber,
    'extensionId': extensionId,
    'anilistMediaId': anilistMediaId,
    'seen': seen,
    'episode': episode?.toJson(),
    'anime': anime?.toJson(),
    'parentList': parentList?.map((e) => e.toJson()).toList(),
    'lastModified': lastModified?.toIso8601String(),
  };

  EpisodeHistoryInstance fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? id;
    title = json['title'];
    episodeNumber = int.tryParse(json['episodeNumber']?.toString() ?? '') ?? 0;
    anilistMediaId = int.tryParse(json['anilistMediaId']?.toString() ?? '') ?? 0;
    extensionId = int.tryParse(json['extensionId']?.toString() ?? '') ?? 0;
    seen = json['seen'] ?? false;

    if (json['episode'] != null) {
      episode = MetiaEpisode()
        ..poster = json['episode']['poster'] ?? ""
        ..name = json['episode']['name'] ?? ""
        ..url = json['episode']['url'] ?? ""
        ..isDub = json['episode']['isDub'] ?? false
        ..isSub = json['episode']['isSub'] ?? false;
    }

    if (json['anime'] != null) {
      anime = MetiaAnime()
        ..name = json['anime']['name']
        ..length = int.tryParse(json['anime']['length']?.toString() ?? '') ?? 0
        ..poster = json['anime']['poster']
        ..url = json['anime']['url'];
    }

    // ✅ parentList parsing
    if (json['parentList'] != null && json['parentList'] is List) {
      parentList = (json['parentList'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => MetiaEpisode()
              ..poster = e['poster'] ?? ""
              ..name = e['name'] ?? ""
              ..url = e['url'] ?? ""
              ..isDub = e['isDub'] ?? false
              ..isSub = e['isSub'] ?? false,
          )
          .toList();
    } else {
      parentList = [];
    }

    DateTime? parsedLastModified;
    if (json['lastModified'] is String) {
      parsedLastModified = DateTime.parse(json['lastModified']).toUtc();
    } else if (json['lastModified'] is DateTime) {
      parsedLastModified = (json['lastModified'] as DateTime).toUtc();
    }
    lastModified = parsedLastModified;

    return this;
  }
}
