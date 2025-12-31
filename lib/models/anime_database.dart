import 'package:isar/isar.dart';

part 'anime_database.g.dart';

@Collection()
class AnimeDatabase {
  Id id = Isar.autoIncrement;

  int? extensionId; // Extension that used to get this episode data
  int? anilistMeidaId; // AniList media id of the anime

  MetiaAnime? matchedAnime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'extensionId': extensionId,
    'anilistMeidaId': anilistMeidaId,
    'matchedAnime': matchedAnime?.toJson(),
  };

  AnimeDatabase fromJson(Map<String, dynamic> json) {
    extensionId = json['extensionId'];
    anilistMeidaId = json['anilistMeidaId'];
    matchedAnime = json['matchedAnime'] != null ? MetiaAnime().fromJson(json['matchedAnime']) : null;
    return this;
  }
}

@embedded
class MetiaAnime {
  late String name;
  late int length;
  late String poster;
  late String url;

  Map<String, dynamic> toJson() => {'name': name, 'length': length, 'poster': poster, 'url': url};
  MetiaAnime fromJson(Map<String, dynamic> json) {
    name = json['name'];
    length = json['length'];
    poster = json['poster'];
    url = json['url'];
    return this;
  }
}

@embedded
class MetiaEpisode {
  late String poster;
  late String name;
  late String url;
  late bool isDub;
  late bool isSub;

  Map<String, dynamic> toJson() => {'poster': poster, 'name': name, 'url': url, 'isDub': isDub, 'isSub': isSub};
}

@embedded
class StreamingData {
  late String link;
  late bool isSub;
  late bool isDub;
  late String name;
  late String m3u8Link;
}
