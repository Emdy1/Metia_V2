import 'package:isar/isar.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/user/credentials.dart';
import 'package:metia/models/log_entry.dart';
import 'package:path_provider/path_provider.dart';

class IsarServices {
  static late final Isar isar;
  static final List<CollectionSchema> schemes = [
    ExtensionSchema,
    UserCredentialsSchema,
    LogEntrySchema,
  ];
  //Note: this should be called first befor any other isar related schemes
  static Future<void> setup() async {
    final appDir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(schemes, directory: appDir.path);
  }
}
