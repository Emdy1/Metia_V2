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
  DateTime? lastModified;

  Map<String, dynamic> toJson() => {
    'id': id, // Send client's Isar ID as 'clientId'
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
    'lastModified': lastModified?.toIso8601String(),
  };

  Extension fromJson(Map<String, dynamic> json) {
    final lastModifiedd = json['lastModified'] != null ? json['lastModified'].toUtc() : DateTime.now().toUtc();
    // id = int.parse(json['id'] ? json['id'].toString() : id.toString());
    id = json["id"];
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
    lastModified = lastModifiedd;
    return this;
  }
}
