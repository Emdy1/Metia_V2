
import 'package:isar/isar.dart';

part 'extension.g.dart';

@Collection()
class Extension {
  Id id = Isar.autoIncrement;

  //those are essential
  String? name;
  String? iconUrl;
  bool? isSub;
  bool? isDub;
  String? language;
  String? anilistPreferedTitle;

  String? jsCode;
  String? jsCodeUrl;
  

  //those are optional
  String? version;
  String? author;
  String? description;

  bool isMain = false;
}