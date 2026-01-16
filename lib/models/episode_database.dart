import 'package:isar/isar.dart';

part 'episode_database.g.dart';

@Collection()
class EpisodeData {
  Id id = Isar.autoIncrement;
  int? progress;
  int? total;
  int? extensionId; // Extension that used to get this episode data
  int? index; // episode number
  int? anilistMediaId; // AniList media id of the anime
  DateTime? lastModified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'total': total,
    'extensionId': extensionId,
    'index': index,
    'anilistMediaId': anilistMediaId,
    'lastModified': lastModified?.toIso8601String(),
  };

  EpisodeData fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? id;
    progress = json['progress'];
    total = json['total'];
    extensionId = int.parse(json['extensionId'].toString());
    index = int.parse(json['index'].toString());
    anilistMediaId = int.parse((json['anilistMediaId'] ?? 0).toString());

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
