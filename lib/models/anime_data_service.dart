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

  

  /// Fetch all extensions and update local list
  Future<void> getEpisodeDatas() async {
    List<EpisodeData> extensions = await db.episodeDatas.where().findAll();
    currentEpisodeDatas.clear();
    currentEpisodeDatas.addAll(extensions);
    notifyListeners();
  }

  /// modify progress of an espiode data
  /// /// Modify progress of an episode data
  Future<void> updateEpisodeProgress({
    required int episodeId,
    double? progress,
    double? total,
  }) async {
    await db.writeTxn(() async {
      final episode = await db.episodeDatas.get(episodeId);
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
