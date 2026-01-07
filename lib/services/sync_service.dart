import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/models/episode_data_service.dart';
import 'package:metia/models/episode_history_instance.dart';
import '../models/anime_database.dart';
import '../models/episode_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/models/anime_database_service.dart';
import 'package:metia/models/episode_history_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService extends ChangeNotifier {
  final String baseUrl = 'https://metiasync.onrender.com';
  // final String baseUrl = 'http://localhost:3000';
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  final ExtensionServices extensionServices;
  final AnimeDatabaseService animeDatabaseService;
  final EpisodeHistoryService episodeHistoryService;
  final EpisodeDataService episodeDataService;

  Timer? _timer;
  bool _disposed = false;

  SyncService({
    required this.extensionServices,
    required this.animeDatabaseService,
    required this.episodeHistoryService,
    required this.episodeDataService,
  });

  Future<Map<String, dynamic>> getLocalSyncData(DateTime since) async {
    final isar = IsarServices.isar;

    final animes = await isar.animeDatabases.where().filter().lastModifiedGreaterThan(since).findAll();
    final episodes = await isar.episodeDatas.where().filter().lastModifiedGreaterThan(since).findAll();
    final extensions = await isar.extensions.where().filter().lastModifiedGreaterThan(since).findAll();
    final history = await isar.episodeHistoryInstances.where().filter().lastModifiedGreaterThan(since).findAll();

    return {
      'animes': animes.map((e) => e.toJson()).toList(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'extensions': extensions.map((e) => e.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  void startSycning(String jwtToken) {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      sync(jwtToken);
      log("INFO: Synced the device with the data from the server");
    });
  }

  // void notifyListeners(); {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!_disposed) notifyListeners();
  //   });
  // }

  /// Orchestrates the sync process: Upload -> Download -> Update Timestamp
  Future<void> sync(String jwtToken) async {
    if (_status == SyncStatus.syncing) return;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getInt('last_sync_time') ?? 0;
      final since = DateTime.fromMillisecondsSinceEpoch(lastSyncTime);

      // 1. Upload local data (only modified data since last sync)
      await uploadSyncData(jwtToken, since);

      // 2. Download and merge server data
      await downloadSyncData(jwtToken, since); // Pass the original 'since' here

      // 3. Update sync time on success
      await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
      _status = SyncStatus.success;
      notifyListeners();
    } catch (e) {
      log('ERROR: Sync failed: $e');
      _status = SyncStatus.error;
      notifyListeners();
      rethrow; // Allow UI to handle the error
    } finally {
      notifyListeners();
      // Reset status to idle after a few seconds to allow for another sync
      Future.delayed(const Duration(seconds: 3), () {
        _status = SyncStatus.idle;
        notifyListeners();
      });
    }
  }

  Future<void> uploadSyncData(String jwtToken, DateTime since) async {
    final data = await getLocalSyncData(since);
    final json = jsonEncode(data);

    final response = await http.post(
      Uri.parse('$baseUrl/sync/upload'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwtToken'},
      body: json,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload sync: ${response.body}');
    }
  }

  Future<void> downloadSyncData(String jwtToken, DateTime since) async {
    // Temporarily force 'since' to epoch for debugging initial sync issues
    // final debugSince = DateTime.fromMillisecondsSinceEpoch(0);
    // print('DEBUG: Forcing download since epoch: $debugSince');

    final response = await http.get(
      Uri.parse('$baseUrl/sync/download'), // Use debugSince here
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

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> mergeServerData(Map<String, dynamic> data) async {
    final isar = IsarServices.isar;

    // Clear existing data to replace with server data
    await isar.writeTxn(() async {
      await isar.animeDatabases.clear();
      await isar.episodeDatas.clear();
      await isar.extensions.clear();
      await isar.episodeHistoryInstances.clear();
    });

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

    // After merging, refresh the service providers to update UI
    await extensionServices.getExtensions();
    await animeDatabaseService.getAnimeDatabases();
    await episodeHistoryService.getEpisodeHistories();
    // EpisodeDataService does not need explicit refresh due to streams.
  }

  Future<void> deleteFromServer(String jwtToken, String type, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/data/delete?type=$type&id=$id'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete from server: ${response.body}');
    }
  }

  Future<void> deleteAllFromServer(String jwtToken, String type) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/data/delete?type=$type&all=true'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete from server: ${response.body}');
    }
  }
}
