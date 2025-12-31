import 'package:isar/isar.dart';

part 'extension.g.dart';

@Collection()
class Extension {
  Id id = Isar.autoIncrement;

  // Essential fields
  String? name;
  String? iconUrl;
  bool? isSub;
  bool? isDub;
  String? language;
  String? anilistPreferedTitle;

  String? jsCode;
  String? jsCodeUrl;

  // Optional fields
  String? version;
  String? author;
  String? description;

  bool isMain = false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconUrl': iconUrl,
    'isSub': isSub,
    'isDub': isDub,
    'language': language,
    'anilistPreferedTitle': anilistPreferedTitle,
    'jsCode': jsCode,
    'jsCodeUrl': jsCodeUrl,
    'version': version,
    'author': author,
    'description': description,
    'isMain': isMain,
  };

  Extension fromJson(Map<String, dynamic> json) {
    name = json['name'];
    iconUrl = json['iconUrl'];
    isSub = json['isSub'];
    isDub = json['isDub'];
    language = json['language'];
    anilistPreferedTitle = json['anilistPreferedTitle'];
    jsCode = json['jsCode'];
    jsCodeUrl = json['jsCodeUrl'];
    version = json['version'];
    author = json['author'];
    description = json['description'];
    isMain = json['isMain'] ?? false;
    return this;
  }
}
