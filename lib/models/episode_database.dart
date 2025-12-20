import 'package:isar/isar.dart';

part 'episode_database.g.dart';

@Collection()
class EpisodeData {
  Id id = Isar.autoIncrement;
  double? progress;
  double? total;
  int? extensionId;
  int? index;
}
