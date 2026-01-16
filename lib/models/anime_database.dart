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
  MetiaEpisode fromJson(Map<String, dynamic> json) {
    name = json["name"];
    poster = json["poster"];
    url = json["url"];
    isDub = json["isDub"];
    isSub = json["isSub"];
    return this;
  }
}

@embedded
class StreamingData {
  late String link;
  late bool isSub;
  late bool isDub;
  late String name;
  late String m3u8Link;

  StreamingData fromJson(Map<String, dynamic> json) {
    link = json["link"];
    isSub = json["isSub"];
    isDub = json["isDub"];
    name = json["name"];
    m3u8Link = json["m3u8Link"];
    return this;
  }
}
