import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/data/user/user_data.dart';
import 'package:metia/models/anime_data_service.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/screens/home_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //never delet this, it should be the first thing to run after "WidgetsFlutterBinding.ensureInitialized();"
  await IsarServices.setup();
  await UserData.initialize();
  await EpisodeDataService.setup();
  await ExtensionServices.setup();

  final episodeDataService = EpisodeDataService();
  await episodeDataService.getEpisodeDatas();

  // Initialize ScriptExecutor early
  final extensionServices = ExtensionServices();
  await extensionServices.getExtensions();
  final manager = ExtensionRuntimeManager(extensionServices);
  await manager.init(); // executor ready here

  //main entry
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: manager),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: extensionServices),
        ChangeNotifierProvider.value(value: episodeDataService),
      ],
      builder: (context, _) {
        final themeProvider = context.watch<ThemeProvider>();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Metia',
          theme: ThemeData(colorScheme: themeProvider.scheme),
          home: const HomePage(),
        );
      },
    ),
  );
}
