import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_database.dart';

class EpisodeDataService extends ChangeNotifier {
  static late final Isar db;

  static Future<void> setup() async {
    db = IsarServices.isar;
  }

  final List<EpisodeData> currentEpisodeDatas = [];

  Future<void> addEpisodeData(EpisodeData episodeData) async {
    await db.writeTxn(() async {
      await db.episodeDatas.put(episodeData);
    });
    await getEpisodeDatas();
  }

  EpisodeData? getEpisodeDataOf(
    int anilistMeidaId,
    int extensionId,
    int index,
  ) {
    EpisodeData? epData;
    if (currentEpisodeDatas
        .where(
          (episodeData) =>
              episodeData.anilistMeidaId == anilistMeidaId &&
              episodeData.extensionId == extensionId &&
              episodeData.index == index,
        )
        .isNotEmpty) {
      epData = currentEpisodeDatas
          .where(
            (episodeData) =>
                episodeData.anilistMeidaId == anilistMeidaId &&
                episodeData.extensionId == extensionId &&
                episodeData.index == index,
          )
          .first;
    }

    return epData;
  }

  /// Fetch all extensions and update local list
  Future<void> getEpisodeDatas() async {
    List<EpisodeData> episodeDatas = await db.episodeDatas.where().findAll();
    currentEpisodeDatas.clear();
    currentEpisodeDatas.addAll(episodeDatas);
    notifyListeners();
  }

  /// modify progress of an espiode data
  Future<void> updateEpisodeProgress({
    EpisodeData? episode,
    double? progress,
    double? total,
  }) async {
    await db.writeTxn(() async {
      //final episode = await db.episodeDatas.get(isarEpisodeId);
      if (episode == null) return;

      if (progress != null) {
        episode.progress = progress;
      }
      if (total != null) {
        episode.total = total;
      }

      await db.episodeDatas.put(episode);
    });

    await getEpisodeDatas();
  }
}
