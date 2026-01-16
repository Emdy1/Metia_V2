import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_database.dart';

class EpisodeDataService extends ChangeNotifier {
  final Isar db;
  late final Stream<List<EpisodeData>> _allEpisodesStream;
  
  List<EpisodeData> _currentEpisodeDatas = [];
  List<EpisodeData> get currentEpisodeDatas => _currentEpisodeDatas;

  EpisodeDataService(this.db) {
    _allEpisodesStream = db.episodeDatas.where().watch(fireImmediately: true);
    _initializeListener();
  }

  void _initializeListener() {
    _allEpisodesStream.listen((episodes) {
      _currentEpisodeDatas = episodes;
      notifyListeners();
    });
  }

  Stream<List<EpisodeData>> watchAllEpisodeDatas() {
    return _allEpisodesStream;
  }

  Future<void> addEpisodeData(EpisodeData episodeData) async {
    await db.writeTxn(() async {
      await db.episodeDatas.put(episodeData);
    });
  }

  Future<EpisodeData?> getEpisodeDataOf(int anilistMediaId, int extensionId, int index) async {
    return await db.episodeDatas
        .where()
        .filter()
        .anilistMediaIdEqualTo(anilistMediaId)
        .extensionIdEqualTo(extensionId)
        .indexEqualTo(index)
        .findFirst();
  }

  Stream<EpisodeData?> watchEpisodeDataOf(int anilistMediaId, int extensionId, int index) {
    return db.episodeDatas
        .where()
        .filter()
        .anilistMediaIdEqualTo(anilistMediaId)
        .extensionIdEqualTo(extensionId)
        .indexEqualTo(index)
        .watch(fireImmediately: true)
        .map((results) => results.isNotEmpty ? results.first : null);
  }

  Future<void> updateEpisodeProgress({EpisodeData? episode, int? progress, int? total}) async {
    if (episode == null) return;

    await db.writeTxn(() async {
      if (progress != null) {
        episode.progress = progress;
      }
      if (total != null) {
        episode.total = total;
      }
      episode.lastModified = DateTime.now().toUtc(); // Update lastModified
      await db.episodeDatas.put(episode);
    });
  }

  Future<void> deleteEpisode(int episodeDataId) async {
    await db.writeTxn(() async {
      await db.episodeDatas.delete(episodeDataId);
    });
  }
  
  @override
  void dispose() {
    // The stream subscription will be automatically cleaned up
    super.dispose();
  }
}