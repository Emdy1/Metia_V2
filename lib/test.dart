import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_js/flutter_js.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/js_core/extension_parser.dart';
import 'package:metia/js_core/script_executor.dart';

class Test1 extends StatefulWidget {
  const Test1({super.key});

  @override
  State<Test1> createState() => Test1State();
}

class Test1State extends State<Test1> {
  late ScriptExecutor executor;
  @override
  void initState() {
    init();
    // TODO: implement initState
    super.initState();
    
  }

  void init() async {
    executor = await ScriptExecutor.create();

    Extension extension = await ExtensionParser.parse(
      "https://raw.githubusercontent.com/Emdy1/Metia_Extenions/refs/heads/main/animepahe_metia_v2.json",
    );

    await executor.loadExtension(extension.jsCode ?? "");
    Logger.log("Extension Loaded");

    String keyword = "hunter x hunter";
    final res = await executor.searchAnime(keyword);
    Logger.log(
      "seccusfully got anime search of $keyword with ${res.length} entries",
    );
    final videoList = await executor.getAnimeEpisodeList(res[0].url);

    final streamData = await executor.getEpisodeStreamData(videoList[0].url);
    print(streamData[0].name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JS Fetch Example')),
      body: Center(child: Text("result")),
    );
  }
}
