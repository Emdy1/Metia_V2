import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_history_instance.dart';

class EpisodeHistoryService extends ChangeNotifier {
  static late final Isar db;

  static Future<void> setup() async {
    db = IsarServices.isar;
  }

  final List<EpisodeHistoryInstance> currentEpisodeHistory = [];

  Future<void> clear() async {
    await db.writeTxn(() async {
      db.episodeHistoryInstances.clear();
    });
    currentEpisodeHistory.clear();
    notifyListeners();
  }

  Future<void> getEpisodeHistories() async {
    List<EpisodeHistoryInstance> histories = await db.episodeHistoryInstances.where().findAll();
    histories.sort((a, b) => b.id.compareTo(a.id));
    currentEpisodeHistory.clear();
    currentEpisodeHistory.addAll(histories);
    notifyListeners();
  }

  Future<void> addEpisodeHistory(EpisodeHistoryInstance episode, {bool fromServer = false}) async {
    if (currentEpisodeHistory.any((e) => e.episode!.url == episode.episode!.url)) {
      EpisodeHistoryInstance existing = currentEpisodeHistory.firstWhere((e) => e.episode!.url == episode.episode!.url);
      await db.writeTxn(() async {
        await db.episodeHistoryInstances.delete(existing.id);
      });
    }

    if (!fromServer) {
      episode.lastModified = DateTime.now().toUtc(); // Set lastModified
    }
    await db.writeTxn(() async {
      await db.episodeHistoryInstances.put(episode);
    });
    await getEpisodeHistories();
  }

  EpisodeHistoryInstance? getEpisodeHistory(int id) {
    return currentEpisodeHistory.where((e) => e.id == id).firstOrNull;
  }

  Future<List<EpisodeHistoryInstance>> getAllEpisodeHistory() async {
    await getEpisodeHistories();
    return currentEpisodeHistory;
  }

  // Future<void> updateEpisodeHistory(EpisodeHistoryInstance episode) async {
  //   await db.writeTxn(() async {
  //     episode.lastModified = DateTime.now(); // Add this line
  //     await db.episodeHistoryInstances.put(episode);
  //   });
  //   await getEpisodeHistories();
  // }

  Future<void> deleteEpisodeHistory(int id) async {
    await db.writeTxn(() async {
      await db.episodeHistoryInstances.delete(id);
    });
    await getEpisodeHistories();
  }

  Future<void> deleteAllEpisodeHistory() async {
    await db.writeTxn(() async {
      await db.episodeHistoryInstances.clear();
    });
    await getEpisodeHistories();
  }
}
