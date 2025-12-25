import 'package:isar/isar.dart';

part 'anime_database.g.dart';

@Collection()
class AnimeDatabase {
  Id id = Isar.autoIncrement;

  int? extensionId; // Extension that used to get this episode data
  int? anilistMeidaId; // AniList media id of the anime

  MetiaAnime? matchedAnime;
}

@embedded
class MetiaAnime {
  late String name;
  late int length;
  late String poster;
  late String url;
}
@embedded
class MetiaEpisode {
  late String poster;
  late String name;
  late String url;
  late bool isDub;
  late bool isSub;
}
@embedded
class StreamingData {
  late String link;
  late bool isSub;
  late bool isDub;
  late String name;
  late String m3u8Link;
}
