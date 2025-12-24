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

  Future<void> getAnimeDatabases() async {
    List<AnimeDatabase> episodeDatas = await db.animeDatabases
        .where()
        .findAll();
    currentAnimeDatabase.clear();
    currentAnimeDatabase.addAll(episodeDatas);
    notifyListeners();
  }

  Future<void> addAnimeDatabases(
    MetiaAnime matchedAnime,
    int anilistMeidaId,
    int extensionId,
  ) async {
    AnimeDatabase anime = AnimeDatabase()
      ..anilistMeidaId = anilistMeidaId
      ..extensionId = extensionId
      ..matchedAnime = matchedAnime;
    await db.writeTxn(() async {
      await db.animeDatabases.put(anime);
    });
    await getAnimeDatabases();
  }

  Future<void> updateAnimeDatabases(
    MetiaAnime matchedAnime,
    int anilistMeidaId,
    int extensionId,
  ) async {
    AnimeDatabase? anime = getAnimeDataOf(anilistMeidaId, extensionId);
    anime!.matchedAnime = matchedAnime;
    await db.writeTxn(() async {
      await db.animeDatabases.put(anime);
    });
    await getAnimeDatabases();
  }

  AnimeDatabase? getAnimeDataOf(int anilistMeidaId, int extensionId) {
    return currentAnimeDatabase
        .where(
          (animeDatabase) =>
              animeDatabase.anilistMeidaId == anilistMeidaId &&
              animeDatabase.extensionId == extensionId,
        )
        .first;
  }

  bool existsInDatabse(int anilistMeidaId, int extensionId) {
    bool exists = currentAnimeDatabase
        .where(
          (animeDatabase) =>
              animeDatabase.anilistMeidaId == anilistMeidaId &&
              animeDatabase.extensionId == extensionId,
        )
        .isNotEmpty;
    return exists;
  }
}
