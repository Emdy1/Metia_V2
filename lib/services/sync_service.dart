import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/data/extensions/extension.dart';
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
  final ExtensionServices extensionServices;
  final AnimeDatabaseService animeDatabaseService;
  final EpisodeHistoryService episodeHistoryService;
  final EpisodeDataService episodeDataService;

  Timer? _timer;
  bool _disposed = false;
  SyncStatus _status = SyncStatus.idle;

  final List<RealtimeChannel> _channels = [];
  final Set<String> _pendingUploadSignatures = {};

  SyncStatus get status => _status;

  SyncService({
    required this.extensionServices,
    required this.animeDatabaseService,
    required this.episodeHistoryService,
    required this.episodeDataService,
  });

  /// -------------------- START --------------------
  Future<void> startSyncing(String supabaseJwt) async {
    await _setSupabaseSession(supabaseJwt);
    _setupRealtimeListeners();
    // _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => sync());
    sync();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final channel in _channels) {
      Supabase.instance.client.removeChannel(channel);
    }
    _timer?.cancel();
    super.dispose();
  }

  /// -------------------- SIGNATURE --------------------
  String _generateSignature(String table, Map<String, dynamic> data) {
    if (data['id'] == null) return '';
    return '$table:${data['id']}';
  }

  /// -------------------- MAIN SYNC --------------------
  /// Only uploads changes. Downloads are handled by realtime listeners.
  Future<void> sync() async {
    if (_status == SyncStatus.syncing) return;

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt('last_sync_time') ?? 0;
      final since = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);

      final syncStartTime = DateTime.now().toUtc();

      final uploaded = await _uploadChanges(since);
      final downloaded = await _downloadAndMerge(since, syncStartTime);
      printData(uploaded, downloaded);
      _status = SyncStatus.success;

      // Update last_sync_time ONLY after successful upload and download
      await prefs.setInt('last_sync_time', syncStartTime.millisecondsSinceEpoch);
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

  /// -------------------- LOG --------------------
  void printData(Map<String, int> upload, Map<String, int> download) {
    Logger.log(
      'INFO: Sync completed | '
      'animes ${upload["animes"] ?? 0}↑ ${download["animes"] ?? 0}↓ | '
      'episodes ${upload["episodes"] ?? 0}↑ ${download["episodes"] ?? 0}↓ | '
      'history ${upload["history"] ?? 0}↑ ${download["history"] ?? 0}↓ | '
      'extensions ${upload["extensions"] ?? 0}↑ ${download["extensions"] ?? 0}↓',
    );
  }

  /// -------------------- SUPABASE SESSION --------------------
  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(decoded);
  }

  Future<void> _setSupabaseSession(String jwt) async {
    final payload = _decodeJwt(jwt);
    final exp = payload['exp'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (exp == null || exp <= now) throw Exception('JWT expired');

    await Supabase.instance.client.auth.recoverSession(
      jsonEncode({
        'access_token': jwt,
        'token_type': 'bearer',
        'expires_at': exp,
        'expires_in': exp - now,
        'refresh_token': null,
        'user': {'id': payload['sub'], 'role': payload['role']},
      }),
    );
  }

  /// -------------------- CASE CONVERSION --------------------
  String _toSnakeCase(String camelCase) =>
      camelCase.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  String _toCamelCase(String snakeCase) => snakeCase.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());

  Map<String, dynamic> _convertKeysToSnakeCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      if (k == 'lastModified') return; // ⛔ DO NOT upload local timestamp
      result[_toSnakeCase(k)] = v;
    });
    return result;
  }

  Map<String, dynamic> _convertKeysToCamelCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      if (k == 'updated_at') {
        result['lastModified'] = DateTime.parse(v);
      } else {
        result[_toCamelCase(k)] = v;
      }
    });
    return result;
  }

  /// -------------------- UPLOAD --------------------
  Future<Map<String, int>> _uploadChanges(DateTime since) async {
    final isar = IsarServices.isar;
    final uid = Supabase.instance.client.auth.currentUser!.id;

    Future<int> upsert<T>(String table, List<T> items, Map<String, dynamic> Function(T) toJson) async {
      if (items.isEmpty) return 0;

      final rows = items.map((item) {
        final json = toJson(item);
        final signature = _generateSignature(table, json);
        if (signature.isNotEmpty) {
          _pendingUploadSignatures.add(signature);
        }
        return {..._convertKeysToSnakeCase(json), 'user_id': uid};
      }).toList();

      if (rows.isEmpty) return 0;
      await Supabase.instance.client.from(table).upsert(rows);
      return rows.length;
    }

    return {
      "extensions": await upsert<Extension>(
        'extensions',
        await isar.extensions.filter().lastModifiedGreaterThan(since).findAll(),
        (e) => e.toJson(),
      ),
      "animes": await upsert<AnimeDatabase>(
        'animes',
        await isar.animeDatabases.filter().lastModifiedGreaterThan(since).findAll(),
        (e) => e.toJson(),
      ),
      "episodes": await upsert<EpisodeData>(
        'episodes',
        await isar.episodeDatas.filter().lastModifiedGreaterThan(since).findAll(),
        (e) => e.toJson(),
      ),
      "history": await upsert<EpisodeHistoryInstance>(
        'episode_history',
        await isar.episodeHistoryInstances.filter().lastModifiedGreaterThan(since).findAll(),
        (e) => e.toJson(),
      ),
    };
  }

  /// -------------------- DOWNLOAD --------------------
  Future<Map<String, int>> _downloadAndMerge(DateTime since, DateTime until) async {
    final client = Supabase.instance.client;
    final sinceStr = since.toUtc().toIso8601String();
    final untilStr = until.toUtc().toIso8601String();
    final animes = await client.from('animes').select().gt('updated_at', sinceStr).lt('updated_at', untilStr);
    final episodes = await client.from('episodes').select().gt('updated_at', sinceStr).lt('updated_at', untilStr);
    final history = await client.from('episode_history').select().gt('updated_at', sinceStr).lt('updated_at', untilStr);
    final extensions = await client.from('extensions').select().gt('updated_at', sinceStr).lt('updated_at', untilStr);
    await _mergeServerData({'animes': animes, 'episodes': episodes, 'history': history, 'extensions': extensions});
    return {
      "animes": animes.length,
      "episodes": episodes.length,
      "history": history.length,
      "extensions": extensions.length,
    };
  }

  /// -------------------- MERGE -------------------- \
  Future<void> _mergeServerData(Map<String, dynamic> data) async {
    for (final e in data['extensions']) {
      await extensionServices.addExtension(Extension().fromJson(_convertKeysToCamelCase(e)), fromServer: true);
    }
    for (final e in data['episodes']) {
      await episodeDataService.addEpisodeData(EpisodeData().fromJson(_convertKeysToCamelCase(e)));
    }
    for (final e in data['animes']) {
      await animeDatabaseService.addAnimeDatabases2(AnimeDatabase().fromJson(_convertKeysToCamelCase(e)));
    }
    for (final e in data['history']) {
      await episodeHistoryService.addEpisodeHistory(
        EpisodeHistoryInstance().fromJson(_convertKeysToCamelCase(e)),
        fromServer: true,
      );
    }
  }

  /// -------------------- REALTIME LISTENERS --------------------
  void _setupRealtimeListeners() {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser!.id;

    final tables = ['extensions', 'animes', 'episodes', 'episode_history'];

    for (final table in tables) {
      final channel = client
          .channel('${table}_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all, // keep all events
            schema: 'public',
            table: table,
            callback: (payload) async {
              final data = payload.newRecord.isEmpty ? payload.oldRecord : payload.newRecord;
              if (data == null) return;

              final signature = _generateSignature(table, data);
              if (signature.isNotEmpty && _pendingUploadSignatures.contains(signature)) {
                _pendingUploadSignatures.remove(signature);
                Logger.log('INFO: Ignored realtime echo for $signature');
                return;
              }

              // locally filter by uid
              // if (data['user_id'] != uid) return;\n
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                case PostgresChangeEvent.update:
                  final prefs = await SharedPreferences.getInstance();
                  final lastSyncMs = prefs.getInt('last_sync_time') ?? 0;
                  final timeFromServer = DateTime.parse(data["updated_at"]).toUtc().millisecondsSinceEpoch;
                  if (!(timeFromServer >= lastSyncMs)) break;
                  await _handleInsertOrUpdate(table, data);
                  break;
                case PostgresChangeEvent.delete:
                  await _handleDelete(table, data);
                  break;
                default:
                  break; // this handles PostgresChangeEvent.all
              }
            },
          )
          .subscribe();

      _channels.add(channel);
    }
  }

  /// -------------------- DELETE --------------------
  Future<void> delete(String table, String id) async {
    await Supabase.instance.client.from(table).delete().eq('id', id);
  }

  Future<void> deleteAll(String table) async {
    // final uid = Supabase.instance.client.auth.currentUser!.id;
    // await Supabase.instance.client.from(table).delete().eq('user_id', uid);
    switch (table) {
      case 'episode_history':
        for (var epHistory in episodeHistoryService.currentEpisodeHistory) {
          delete(table, epHistory.id.toString());
        }
        break;
      case 'extensions':
        for (var ext in extensionServices.currentExtensions) {
          delete(table, ext.id.toString());
        }
        break;
      case 'animes':
        for (var animeDb in animeDatabaseService.currentAnimeDatabase) {
          delete(table, animeDb.id.toString());
        }
        break;
      case 'episodes':
        for (var episodeDb in episodeDataService.currentEpisodeDatas) {
          delete(table, episodeDb.id.toString());
        }
        break;
    }
  }

  Future<void> _handleInsertOrUpdate(String table, Map<String, dynamic> data) async {
    if (data == null) return;
    switch (table) {
      case 'extensions':
        await extensionServices.addExtension(Extension().fromJson(_convertKeysToCamelCase(data)), fromServer: true);
        Logger.log("received an Extension");
        break;
      case 'animes':
        await animeDatabaseService.addAnimeDatabases2(AnimeDatabase().fromJson(_convertKeysToCamelCase(data)));
        Logger.log("received an AnimeData");

        break;
      case 'episodes':
        await episodeDataService.addEpisodeData(EpisodeData().fromJson(_convertKeysToCamelCase(data)));
        Logger.log("received an EpisodeData");

        break;
      case 'episode_history':
        await episodeHistoryService.addEpisodeHistory(
          EpisodeHistoryInstance().fromJson(_convertKeysToCamelCase(data)),
          fromServer: true,
        );
        Logger.log("received an Episode History");

        break;
    }
  }

  Future<void> _handleDelete(String table, Map<String, dynamic> data) async {
    if (data == null) return;
    switch (table) {
      case 'extensions':
        await extensionServices.deleteExtension(data['id']);
        Logger.log("deleted an Extension");

        break;
      case 'animes':
        await animeDatabaseService.deleteAnime(data['id']);
        Logger.log("deleted an AniemData");

        break;
      case 'episodes':
        await episodeDataService.deleteEpisode(data['id']);
        Logger.log("deleted an EpisodeData");

        break;
      case 'episode_history':
        await episodeHistoryService.deleteEpisodeHistory(data['id']);
        Logger.log("deleted an Episode History");

        break;
    }
  }
}
