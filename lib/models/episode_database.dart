import 'package:isar/isar.dart';

part 'episode_database.g.dart';

@Collection()
class EpisodeData {
  Id id = Isar.autoIncrement;
  double? progress;
  double? total;
  int? extensionId; // Extension that used to get this episode data
  int? index; // episode number
  int? anilistMeidaId; // AniList media id of the anime

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'total': total,
    'extensionId': extensionId,
    'index': index,
    'anilistMeidaId': anilistMeidaId,
  };

  EpisodeData fromJson(Map<String, dynamic> json) {
    progress = json['progress'];
    total = json['total'];
    extensionId = json['extensionId'];
    index = json['index'];
    anilistMeidaId = json['anilistMeidaId'];
    return this;
  }
}
