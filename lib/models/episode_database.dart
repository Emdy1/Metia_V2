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
  DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress': progress,
        'total': total,
        'extensionId': extensionId,
        'index': index,
        'anilistMeidaId': anilistMeidaId,
        'lastModified': lastModified?.toIso8601String(),
      };

  EpisodeData fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? id;
    progress = json['progress'];
    total = json['total'];
    extensionId = int.parse(json['extensionId']);
    index = int.parse(json['index']);
    anilistMeidaId = int.parse(json['anilistMeidaId']);
    lastModified = json['lastModified'] != null
        ? DateTime.parse(json['lastModified'])
        : DateTime.now();
    return this;
  }
}
