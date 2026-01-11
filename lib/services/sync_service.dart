import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/extensions/extension_services.dart';

import 'package:metia/models/anime_database.dart';
import 'package:metia/models/anime_database_service.dart';
import 'package:metia/models/episode_database.dart';
import 'package:metia/models/episode_data_service.dart';
import 'package:metia/models/episode_history_instance.dart';
import 'package:metia/models/episode_history_service.dart';
import 'package:metia/models/logger.dart';

/// -------------------- STATUS --------------------

enum SyncStatus { idle, syncing, success, error }

/// -------------------- SERVICE --------------------

class SyncService extends ChangeNotifier {
  // final String baseUrl = 'http://localhost:3000';
  final String baseUrl = 'https://metiasync.onrender.com';

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

  /// -------------------- START --------------------

  void startSyncing(String jwtToken) {
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => sync(jwtToken));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  /// -------------------- MAIN SYNC --------------------

  Future<void> sync(String jwtToken) async {
    if (_status == SyncStatus.syncing) return;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt('last_sync_time') ?? 0;
      final isFirstSync = lastSyncMs == 0;
      final since = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

      if (isFirstSync) {
        // On first sync, download ALL data from server
        await _downloadAndMerge(jwtToken, DateTime.fromMillisecondsSinceEpoch(0));
      } else {
        // Normal sync: upload then download changes
        await _uploadChanges(jwtToken, since);
        await _downloadAndMerge(jwtToken, since);
      }

      await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
      _status = SyncStatus.success;
      Logger.log('INFO: Sync completed');
    } catch (e, st) {
      Logger.log('ERROR: Sync failed $e\n$st');
      _status = SyncStatus.error;
    } finally {
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        if (!_disposed) {
          _status = SyncStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  /// -------------------- UPLOAD --------------------

  Future<void> _uploadChanges(String jwtToken, DateTime since) async {
    final isar = IsarServices.isar;

    final payload = {
      'animes': (await isar.animeDatabases.filter().lastModifiedGreaterThan(since).findAll())
          .map((e) => e.toJson())
          .toList(),

      'episodes': (await isar.episodeDatas.filter().lastModifiedGreaterThan(since).findAll())
          .map((e) => e.toJson())
          .toList(),

      'history': (await isar.episodeHistoryInstances.filter().lastModifiedGreaterThan(since).findAll())
          .map((e) => e.toJson())
          .toList(),

      'extensions': (await isar.extensions.filter().lastModifiedGreaterThan(since).findAll())
          .map((e) => e.toJson())
          .toList(),
    };

    final res = await http.post(
      Uri.parse('$baseUrl/sync/upload'),
      headers: {'Authorization': 'Bearer $jwtToken', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('Upload failed: ${res.body}');
    }
  }

  /// -------------------- DOWNLOAD --------------------

  Future<void> _downloadAndMerge(String jwtToken, DateTime since) async {
    final res = await http.get(
      Uri.parse('$baseUrl/sync/download?since=${since.millisecondsSinceEpoch}'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (res.statusCode != 200) {
      throw Exception('Download failed: ${res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    await _mergeServerData(data);
  }

  /// -------------------- MERGE --------------------

  Future<void> _mergeServerData(Map<String, dynamic> data) async {
    final isar = IsarServices.isar;

    await isar.writeTxn(() async {
      await _mergeCollection(isar.animeDatabases, data['animes'], (j) => AnimeDatabase().fromJson(j));

      await _mergeCollection(isar.episodeDatas, data['episodes'], (j) => EpisodeData().fromJson(j));

      await _mergeCollection(isar.extensions, data['extensions'], (j) => Extension().fromJson(j));

      await _mergeCollection(
        isar.episodeHistoryInstances,
        data['history'],
        (j) => EpisodeHistoryInstance().fromJson(j),
      );
    });

    await extensionServices.getExtensions();
    await animeDatabaseService.getAnimeDatabases();
    await episodeHistoryService.getEpisodeHistories();
  }

  Future<void> _mergeCollection<T>(
    IsarCollection<T> collection,
    List<dynamic>? incoming,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (incoming == null) return;

    for (final json in incoming) {
      final incomingObj = fromJson(json);
      final dynamic id = (incomingObj as dynamic).id;

      final local = await collection.get(id);

      if (local == null || (incomingObj as dynamic).lastModified.isAfter((local as dynamic).lastModified)) {
        await collection.put(incomingObj);
      }
    }
  }

  /// -------------------- DELETE (MATCHES SERVER) --------------------

  Future<void> deleteFromServer(String jwtToken, String type, String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/data/delete?type=$type&id=$id'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (res.statusCode != 200) {
      throw Exception('Delete failed: ${res.body}');
    }
  }

  Future<void> deleteAllFromServer(String jwtToken, String type) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/data/delete?type=$type&all=true'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (res.statusCode != 200) {
      throw Exception('Delete all failed: ${res.body}');
    }
  }
}
