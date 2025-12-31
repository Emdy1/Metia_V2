import 'package:isar/isar.dart';

part 'anime_database.g.dart';

@Collection()
class AnimeDatabase {
  Id id = Isar.autoIncrement;

  int? extensionId; // Extension that used to get this episode data
  int? anilistMediaId; // AniList media id of the anime

  MetiaAnime? matchedAnime;
  DateTime? lastModified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'extensionId': extensionId,
    'anilistMediaId': anilistMediaId,
    'matchedAnime': matchedAnime?.toJson(),
    'lastModified': lastModified?.toIso8601String(),
  };

  AnimeDatabase fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? id;
    extensionId = int.parse(json['extensionId']);
    anilistMediaId = int.parse((json['anilistMediaId'].toString()));
    matchedAnime = json['matchedAnime'] != null ? MetiaAnime().fromJson(json['matchedAnime']) : null;
    lastModified = json['lastModified'] != null ? DateTime.parse(json['lastModified']) : DateTime.now();
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
