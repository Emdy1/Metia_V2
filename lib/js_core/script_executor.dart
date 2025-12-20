import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/js_core/anime.dart';
import 'package:metia/models/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScriptExecutor {
  late final WebViewController controller;
  final Map<String, Completer<dynamic>> _pendingCalls = {};
  bool initialized = false;
  bool _disposed = false;

  ScriptExecutor._(this.controller);

  static Future<ScriptExecutor> create() async {
    final controller = WebViewController();
    final completer = Completer<void>();
    final executor = ScriptExecutor._(controller);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: executor._onJsMessage,
      )
      ..addJavaScriptChannel(
        'nativeFetch',
        onMessageReceived: executor._onNativeFetch,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await controller.runJavaScript(executor._bridgeJs);
            executor.initialized = true;
            completer.complete();
          },
        ),
      )
      ..loadHtmlString(executor._html, baseUrl: 'https://localhost/');

    await completer.future;
    return executor;
  }

  // ---------- JS -> Dart (function result) ----------
  void _onJsMessage(JavaScriptMessage msg) {
    final payload = jsonDecode(msg.message);
    final String id = payload['id'];
    final dynamic data = payload['data'];

    _pendingCalls[id]?.complete(data);
    _pendingCalls.remove(id);
  }

  // ---------- JS -> Dart (native fetch) ----------
  Future<void> _onNativeFetch(JavaScriptMessage msg) async {
    final payload = jsonDecode(msg.message);
    final callId = payload['callId'];
    final url = payload['url'];
    final headers = Map<String, String>.from(payload['headers'] ?? {});

    try {
      final res = await http.get(Uri.parse(url), headers: headers);

      final result = {
        'callId': callId,
        'status': res.statusCode,
        'body': res.body,
      };

      await controller.runJavaScript(
        'window.__nativeFetchCallback(${jsonEncode(result)})',
      );
    } catch (e) {
      await controller.runJavaScript(
        'window.__nativeFetchCallback(${jsonEncode({'callId': callId, 'error': e.toString()})})',
      );
    }
  }

  // ---------- Dart -> JS ----------
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Clear pending calls to prevent dangling futures
    for (var completer in _pendingCalls.values) {
      if (!completer.isCompleted) {
        completer.completeError('ScriptExecutor disposed');
      }
    }
    _pendingCalls.clear();

    // Remove JS channels (WebViewController doesn't provide a direct remove method,
    // but setting a fresh controller or nulling references helps garbage collection)
    // If you recreated a new WebView, old channels will be GC'd.

    // Nullify controller reference
    // (optional but helps GC in long-living executors)
    // controller = null; // not possible since it's late final
  }

  Future<dynamic> call(String fn, List args) {
    if (_disposed) {
      throw Exception('ScriptExecutor has been disposed');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<dynamic>();
    _pendingCalls[id] = completer;

    controller.runJavaScript(
      'window.__call("$id", "$fn", ${jsonEncode(args)});',
    );

    return completer.future;
  }

  Future<void> loadExtension(String jsCode) async {
    if (!initialized) {
      throw Exception('JS runtime not initialized yet');
    }
    await controller.runJavaScript(jsCode);
    
  }

  Future<List<MetiaAnime>> searchAnime(String keyword) async {
    final data = await call('searchAnime', [keyword]);
    List<MetiaAnime> animes = [];
    for (var anime in data["data"] as List) {
      final metiaAnime = MetiaAnime();
      metiaAnime.name = anime["title"];
      metiaAnime.length = anime["episodes"];
      metiaAnime.poster = anime["poster"];
      metiaAnime.url = anime["session"];
      animes.add(metiaAnime);
    }
    return animes;
  }

  Future<List<MetiaEpisode>> getAnimeEpisodeList(String url) async {
    final data = await call('getAnimeEpisodeList', [url]);

    List<MetiaEpisode> episodes = [];
    for (var episode in data["data"] as List) {
      final metiaEpisode = MetiaEpisode();
      metiaEpisode.name = episode["name"];
      metiaEpisode.poster = episode["cover"];
      metiaEpisode.url = episode["id"];
      metiaEpisode.isDub = episode["dub"];
      metiaEpisode.isSub = episode["sub"];
      episodes.add(metiaEpisode);
    }
    return episodes;
  }

  Future<List<StreamingData>> getEpisodeStreamData(String url) async {
    final data = await call('getEpisodeStreamData', [url]);

    List<StreamingData> streamingDatas = [];

    for (var streamingData in data["data"] as List) {
      final _streamingData = StreamingData();
      _streamingData.isDub = streamingData["dub"];
      _streamingData.isSub = streamingData["sub"];
      _streamingData.link = streamingData["link"];
      _streamingData.m3u8Link = streamingData["m3u8"];
      _streamingData.name = streamingData["provider"];
      streamingDatas.add(_streamingData);
    }

    return streamingDatas;
  }

  // ---------- JS BRIDGE ----------
  final String _bridgeJs = '''
(function () {

  window.__pendingFetchCalls = {};

  window.fetchViaNative = function (url, headers = {}) {
    return new Promise((resolve, reject) => {
      const callId = Math.random().toString(36).slice(2);
      window.__pendingFetchCalls[callId] = { resolve, reject };

      nativeFetch.postMessage(JSON.stringify({
        callId,
        url,
        headers
      }));
    });
  };

  window.__nativeFetchCallback = function (payload) {
    const call = window.__pendingFetchCalls[payload.callId];
    if (!call) return;

    delete window.__pendingFetchCalls[payload.callId];

    if (payload.error) {
      call.reject(new Error(payload.error));
    } else {
      call.resolve({
        status: payload.status,
        body: payload.body
      });
    }
  };

  window.__call = async function (id, fn, args) {
    try {
      const res = await window[fn](...args);
      Flutter.postMessage(JSON.stringify({ id, data: res }));
    } catch (e) {
      Flutter.postMessage(JSON.stringify({
        id,
        data: { error: e.message }
      }));
    }
  };

})();
''';

  final String _html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width">
</head>
<body></body>
</html>
''';
}
