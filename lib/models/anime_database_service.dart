import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/anime_database.dart';

class AnimeDatabaseService extends ChangeNotifier {
  static late final Isar db;

  static Future<void> setup() async {
    db = IsarServices.isar;
  }

  final List<AnimeDatabase> currentAnimeDatabase = [];

  Future<void> clear() async {
    await db.writeTxn(() async {
      db.animeDatabases.clear();
    });
    currentAnimeDatabase.clear();
    notifyListeners();
  }

  Future<void> getAnimeDatabases() async {
    List<AnimeDatabase> episodeDatas = await db.animeDatabases.where().findAll();
    currentAnimeDatabase.clear();
    currentAnimeDatabase.addAll(episodeDatas);
    notifyListeners();
  }

  Future<void> addAnimeDatabases2(AnimeDatabase animeDb) async {
    await db.writeTxn(() async {
      await db.animeDatabases.put(animeDb);
    });
    await getAnimeDatabases();
  }

  Future<void> addAnimeDatabases(MetiaAnime matchedAnime, int anilistMediaId, int extensionId) async {
    AnimeDatabase anime = AnimeDatabase()
      ..anilistMediaId = anilistMediaId
      ..extensionId = extensionId
      ..matchedAnime = matchedAnime;
    anime.lastModified ??= DateTime.now().toUtc(); // Set lastModified
    await db.writeTxn(() async {
      await db.animeDatabases.put(anime);
    });
    await getAnimeDatabases();
  }

  Future<void> updateAnimeDatabases(MetiaAnime matchedAnime, int anilistMediaId, int extensionId) async {
    AnimeDatabase? anime = getAnimeDataOf(anilistMediaId, extensionId);
    anime ??= AnimeDatabase()
      ..anilistMediaId = anilistMediaId
      ..extensionId = extensionId
      ..matchedAnime = matchedAnime;
    anime.matchedAnime = matchedAnime;
    anime.lastModified = DateTime.now().toUtc(); // Set lastModified
    await db.writeTxn(() async {
      await db.animeDatabases.put(anime!);
    });
    await getAnimeDatabases();
  }

  AnimeDatabase? getAnimeDataOf(int anilistMediaId, int extensionId) {
    return currentAnimeDatabase
        .where(
          (animeDatabase) => animeDatabase.anilistMediaId == anilistMediaId && animeDatabase.extensionId == extensionId,
        )
        .firstOrNull;
  }

  bool existsInDatabse(int anilistMediaId, int extensionId) {
    bool exists = currentAnimeDatabase
        .where(
          (animeDatabase) => animeDatabase.anilistMediaId == anilistMediaId && animeDatabase.extensionId == extensionId,
        )
        .isNotEmpty;
    return exists;
  }

  Future<void> deleteAnime(int animeDbInt) async {
    await db.writeTxn(() async {
      await db.animeDatabases.delete(animeDbInt);
    });
    await getAnimeDatabases();
  }
}
