import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/data/user/user_data.dart';
import 'package:metia/models/anime_database_service.dart';
import 'package:metia/models/episode_data_service.dart';
import 'package:metia/models/episode_history_service.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/screens/home_page.dart';
import 'package:metia/services/sync_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  //never delete this, it should be run only after "WidgetsFlutterBinding.ensureInitialized();"
  await IsarServices.setup();
  await UserData.initialize();
  await ExtensionServices.setup();
  await AnimeDatabaseService.setup();
  await EpisodeHistoryService.setup();

  //init the episode data service
  final episodeDataService = EpisodeDataService(IsarServices.isar);

  //init the anime data service
  final animeDatabaseService = AnimeDatabaseService();
  await animeDatabaseService.getAnimeDatabases();

  //init anime history service
  final animeHistoryService = EpisodeHistoryService();
  await animeHistoryService.getEpisodeHistories();

  //init ScriptExecutor early
  final extensionServices = ExtensionServices();
  await extensionServices.getExtensions();
  final manager = ExtensionRuntimeManager(extensionServices);
  await manager.init(); // executor ready here

  //init sync service
  final syncService = SyncService(
    animeDatabaseService: animeDatabaseService,
    episodeHistoryService: animeHistoryService,
    extensionServices: extensionServices,
    episodeDataService: episodeDataService,
  );

  //main entry
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: manager),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: extensionServices),
        ChangeNotifierProvider.value(value: episodeDataService),
        ChangeNotifierProvider.value(value: animeDatabaseService),
        ChangeNotifierProvider.value(value: animeHistoryService),
        ChangeNotifierProvider.value(value: syncService),
      ],
      builder: (context, _) {
        final themeProvider = context.watch<ThemeProvider>();

        return MaterialApp(
          //showPerformanceOverlay: true,
          debugShowCheckedModeBanner: false,
          title: 'Metia',
          theme: ThemeData(colorScheme: themeProvider.scheme),
          home: const HomePage(),
        );
      },
    ),
  );
}
