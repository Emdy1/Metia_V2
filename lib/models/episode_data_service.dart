import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_database.dart';

class EpisodeDataService extends ChangeNotifier {
  final Isar db;
  late final Stream<List<EpisodeData>> _allEpisodesStream;

  EpisodeDataService(this.db) {
    _allEpisodesStream =
        db.episodeDatas.where().watch(fireImmediately: true);
  }

  Stream<List<EpisodeData>> watchAllEpisodeDatas() {
    return _allEpisodesStream;
  }

  Future<void> addEpisodeData(EpisodeData episodeData) async {
    await db.writeTxn(() async {
      await db.episodeDatas.put(episodeData);
    });
  }

  Future<EpisodeData?> getEpisodeDataOf(
    int anilistMeidaId,
    int extensionId,
    int index,
  ) async {
    return await db.episodeDatas
        .where()
        .filter()
        .anilistMeidaIdEqualTo(anilistMeidaId)
        .extensionIdEqualTo(extensionId)
        .indexEqualTo(index)
        .findFirst();
  }

  Stream<EpisodeData?> watchEpisodeDataOf(
    int anilistMeidaId,
    int extensionId,
    int index,
  ) {
    return db.episodeDatas
        .where()
        .filter()
        .anilistMeidaIdEqualTo(anilistMeidaId)
        .extensionIdEqualTo(extensionId)
        .indexEqualTo(index)
        .watch(fireImmediately: true)
        .map((results) => results.isNotEmpty ? results.first : null);
  }

  Future<void> updateEpisodeProgress({
    EpisodeData? episode,
    double? progress,
    double? total,
  }) async {
    if (episode == null) return;

    await db.writeTxn(() async {
      if (progress != null) {
        episode.progress = progress;
      }
      if (total != null) {
        episode.total = total;
      }
      episode.lastModified = DateTime.now(); // Set lastModified
      await db.episodeDatas.put(episode);
    });
  }
}
