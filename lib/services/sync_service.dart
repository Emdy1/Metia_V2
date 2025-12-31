import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_history_instance.dart';
import '../models/anime_database.dart';
import '../models/episode_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final String baseUrl = 'https://metiasync.onrender.com';

  SyncService();

  Future<Map<String, dynamic>> getLocalSyncData() async {
    final isar = IsarServices.isar;

    final animes = await isar.animeDatabases.where().findAll();
    final episodes = await isar.episodeDatas.where().findAll();
    final extensions = await isar.extensions.where().findAll();
    final history = await isar.episodeHistoryInstances.where().findAll();

    return {
      'animes': animes.map((e) => e.toJson()).toList(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'extensions': extensions.map((e) => e.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(), // <-- added
    };
  }

  /// Orchestrates the sync process: Upload -> Download -> Update Timestamp
  Future<void> sync(String jwtToken) async {
    try {
      // 1. Upload local data (Note: Currently uploads everything. Optimization needed for large DBs)
      await uploadSyncData(jwtToken);

      // 2. Get last sync time
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getInt('last_sync_time') ?? 0;
      final since = DateTime.fromMillisecondsSinceEpoch(lastSyncTime);

      // 3. Download and merge server data
      await downloadSyncData(jwtToken, since);

      // 4. Update sync time on success
      await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Sync failed: $e');
      rethrow; // Allow UI to handle the error
    }
  }

  Future<void> uploadSyncData(String jwtToken) async {
    final data = await getLocalSyncData();

    final response = await http.post(
      Uri.parse('$baseUrl/sync/upload'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print('Sync uploaded successfully!');
    } else {
      throw Exception('Failed to upload sync: ${response.body}');
    }
  }

  Future<void> downloadSyncData(String jwtToken, DateTime since) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/download?since=${since.millisecondsSinceEpoch}'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final serverData = jsonDecode(response.body);
      // Use serverData to merge into local Isar database
      await mergeServerData(serverData);
    } else {
      throw Exception('Failed to download sync: ${response.body}');
    }
  }

  Future<void> mergeServerData(Map<String, dynamic> data) async {
    final isar = IsarServices.isar;

    final animes = data['animes'] as List;
    final episodes = data['episodes'] as List;
    final extensions = data['extensions'] as List;
    final history = data['history'] as List; // <-- added

    await isar.writeTxn(() async {
      for (var animeJson in animes) {
        await isar.animeDatabases.put(AnimeDatabase().fromJson(animeJson));
      }
      for (var epJson in episodes) {
        await isar.episodeDatas.put(EpisodeData().fromJson(epJson));
      }
      for (var extJson in extensions) {
        await isar.extensions.put(Extension().fromJson(extJson));
      }
      for (var histJson in history) {
        await isar.episodeHistoryInstances.put(EpisodeHistoryInstance().fromJson(histJson));
      }
    });
  }
}
