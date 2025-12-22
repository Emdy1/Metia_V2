import 'package:isar/isar.dart';

part 'episode_database.g.dart';

@Collection()
class EpisodeData {
  Id id = Isar.autoIncrement;
  double? progress;
  double? total;
  int? extensionId; //Extension that used to get this episode data
  int? index; //episode nummber
  int? anilistMeidaId; // anilist media id of the anime 
}
