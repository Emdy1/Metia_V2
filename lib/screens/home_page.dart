import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/models/episode_history_service.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/screens/extensions_page.dart';
import 'package:metia/screens/home/explorer_page.dart';
import 'package:metia/screens/home/history_page.dart';
import 'package:metia/screens/home/library_page.dart';
import 'package:metia/screens/home/profile_page.dart';
import 'package:http/http.dart' as http;
import 'package:metia/screens/logging_page.dart';
import 'package:metia/services/sync_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Uri>? _linkSubscription;
  int _tabLength = 3;
  bool alreadySyncedOnce = false;

  @override
  void initState() {
    super.initState();
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    _tabLength = isLoggedIn ? 4 : 3;

    Provider.of<ExtensionServices>(context, listen: false).getExtensions();
    _tabController = TabController(length: _tabLength, vsync: this);

    // Listen to login state changes
    Provider.of<UserProvider>(context, listen: false).addListener(_onLoginStateChanged);
    initDeepLinks();
  }

  void _onLoginStateChanged() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final newLength = userProvider.isLoggedIn ? 4 : 3;
    if (userProvider.isMetiaSyncready && alreadySyncedOnce == false) {
      final token = Provider.of<UserProvider>(context, listen: false).JWTtoken;
      if (token != null) {
        //Provider.of<SyncService>(context, listen: false).startSycning(token);
      }
      alreadySyncedOnce = true;
    }

    if (newLength != _tabLength) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabLength = newLength;
      _tabController = TabController(length: _tabLength, vsync: this);

      // Preserve the tab index if possible
      if (oldIndex < _tabLength) {
        _tabController.index = oldIndex;
      }

      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    Provider.of<UserProvider>(context, listen: false).removeListener(_onLoginStateChanged);
    _linkSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) async {
      Logger.log('Received deep link: $uri');
      final authorizationCode = uri.toString().replaceAll("metia://?code=", "");

      final tokenEndpoint = Uri.https('anilist.co', '/api/v2/oauth/token');
      final payload = {
        'grant_type': 'authorization_code',
        'client_id': '25588',
        'client_secret': 'QCzgwOKG6kJRzRL91evKRXXGfDCHlmgXfi44A0Ok',
        'redirect_uri': 'metia://',
        'code': authorizationCode,
      };

      try {
        final response = await http.post(
          tokenEndpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (mounted) {
            Provider.of<UserProvider>(context, listen: false).logIn(responseData['access_token'].toString());
          } else {
            Logger.log('not mounted', level: 'INFO', details: 'Widget not mounted when trying to log in user');
          }
        } else {
          Logger.log('Failed to retrieve access token: ${response.body}', level: 'ERROR');
        }
      } catch (e) {
        Logger.log('Request failed: $e', level: 'ERROR');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          if (isLandscape) _buildNavigationRail(),
          if (isLandscape) const VerticalDivider(thickness: 1),
          Expanded(child: _buildTabBarView()),
        ],
      ),
      bottomNavigationBar: !isLandscape ? _buildBottomNavigationBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      actions: const [_SyncIndicator(), _AppBarMenu()],
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SvgPicture.asset('assets/icons/logo.svg', height: 24, width: 24),
        ),
      ),
      title: const Text('Metia'),
    );
  }

  Widget _buildNavigationRail() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: Selector<UserProvider, bool>(
        selector: (_, provider) => provider.isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return NavigationRail(
            selectedIndex: _tabController.index,
            onDestinationSelected: (index) {
              setState(() => _tabController.index = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              if (isLoggedIn) const NavigationRailDestination(icon: Icon(Icons.home), label: Text('Library')),
              const NavigationRailDestination(icon: Icon(Icons.explore), label: Text('Explore')),
              const NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
              const NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: Selector<UserProvider, bool>(
        selector: (_, provider) => provider.isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return BottomNavigationBar(
            currentIndex: _tabController.index,
            onTap: (index) => setState(() => _tabController.index = index),
            items: [
              if (isLoggedIn) const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Library'),
              const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
              const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
            type: BottomNavigationBarType.fixed,
          );
        },
      ),
    );
  }

  Widget _buildTabBarView() {
    return Selector<UserProvider, bool>(
      selector: (_, provider) => provider.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Prevent swipe interference
          children: [
            if (isLoggedIn) const LibraryPage(),
            const ExplorerPage(),
            const HistoryPage(),
            const ProfilePage(),
          ],
        );
      },
    );
  }
}

// Separate widget for AppBar menu to prevent unnecessary rebuilds
class _AppBarMenu extends StatelessWidget {
  const _AppBarMenu();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: Selector<UserProvider, bool>(
        selector: (_, provider) => provider.isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _switchMenuButtons(value, context),
            itemBuilder: (BuildContext context) =>
                isLoggedIn ? _loggedMenuItemList(context) : _defaultMenuItemList(context),
          );
        },
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        switch (syncService.status) {
          case SyncStatus.syncing:
            return Container(
              padding: const EdgeInsets.all(12.0),
              width: 48.0,
              height: 48.0,
              child: const CircularProgressIndicator(strokeWidth: 2.0),
            );
          case SyncStatus.success:
            return const Icon(Icons.check_circle, color: Colors.green);
          case SyncStatus.error:
            return const Icon(Icons.error, color: Colors.red);
          case SyncStatus.idle:
            return SizedBox.shrink();
          default:
            return const SizedBox.shrink(); // Show nothing when idle
        }
      },
    );
  }
}

List<PopupMenuEntry<String>> _defaultMenuItemList(context) {
  final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  return [
    const PopupMenuItem<String>(enabled: true, height: 36, value: 'logs', child: Text('Logs')),
    const PopupMenuItem<String>(value: 'extensions', height: 36, child: Text('Extensions')),
    const PopupMenuItem<String>(value: 'Settings', height: 36, child: Text('Settings')),
    const PopupMenuItem<String>(value: 'clearHistory', height: 36, child: Text('Clear History')),
    PopupMenuItem<String>(
      value: 'revertTheme',
      height: 36,
      child: Text('Switch to ${isDarkMode ? "Light" : "Dark"} Mode'),
    ),
  ];
}

List<PopupMenuEntry<String>> _loggedMenuItemList(BuildContext context) {
  final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  return [
    const PopupMenuItem<String>(enabled: false, height: 36, child: Text('Library')),
    const PopupMenuItem<String>(value: 'sync', height: 36, child: Text('Sync')),
    const PopupMenuItem<String>(value: 'refresh', height: 36, child: Text('Refresh')),
    const PopupMenuItem<String>(value: 'createList', height: 36, child: Text('Create a New List')),
    const PopupMenuItem<String>(height: 36, enabled: false, child: Text('Profile', textAlign: TextAlign.end)),
    const PopupMenuItem<String>(value: 'logout', height: 36, child: Text('Log Out')),
    const PopupMenuItem<String>(height: 36, enabled: false, child: Text('General', textAlign: TextAlign.end)),
    const PopupMenuItem<String>(value: 'clearHistory', height: 36, child: Text('Clear History')),
    PopupMenuItem<String>(
      value: 'revertTheme',
      height: 36,
      child: Text('Switch to ${isDarkMode ? "Light" : "Dark"} Mode'),
    ),
    const PopupMenuItem<String>(value: 'extensions', height: 36, child: Text('Extensions')),
    const PopupMenuItem<String>(value: 'Settings', height: 36, child: Text('Settings')),
    const PopupMenuItem<String>(value: 'logs', height: 36, child: Text('Logs')),
  ];
}

void _switchMenuButtons(String value, BuildContext context) {
  switch (value) {
    case 'sync':
      final token = Provider.of<UserProvider>(context, listen: false).JWTtoken;
      if (token != null) {
        Provider.of<SyncService>(context, listen: false).sync(token);
      }
      break;
    case 'clearHistory':
      () async {
        String token = Provider.of<UserProvider>(context, listen: false).JWTtoken!;
        await Provider.of<SyncService>(context, listen: false).deleteAllFromServer(token, "history");
        await Provider.of<EpisodeHistoryService>(context, listen: false).deleteAllEpisodeHistory();
      }();
      break;
    case 'extensions':
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ExtensionsPage()));
      break;
    case 'logs':
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoggingPage()));
      break;
    case 'logout':
      Provider.of<UserProvider>(context, listen: false).logOut();
      break;
    case 'refresh':
      Provider.of<UserProvider>(context, listen: false).reloadUserData();
      break;
    case 'createList':
      _showCreateCustomListDialog(
        context,
        onAdd: (name) async {
          try {
            await Provider.of<UserProvider>(context, listen: false).createCustomList(name);
            await Provider.of<UserProvider>(context, listen: false).reloadUserData();
            return true;
          } catch (_) {
            return false;
          }
        },
      );
      break;
    case 'revertTheme':
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (themeProvider.isDarkMode) {
        themeProvider.setLightMode();
      } else {
        themeProvider.setDarkMode();
      }
      break;
  }
}

void _showCreateCustomListDialog(BuildContext context, {required Future<bool> Function(String) onAdd}) {
  final TextEditingController textController = TextEditingController();
  bool hasError = false;

  showDialog(
    context: context,
    builder: (context) {
      textController.clear();
      hasError = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Custom List'),
            content: TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'List Name',
                errorText: hasError ? 'Name cannot be empty or already exists' : null,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = textController.text.trim();
                  if (name.isEmpty) {
                    setState(() {
                      hasError = true;
                    });
                    return;
                  }

                  final success = await onAdd(name);

                  if (success) {
                    Navigator.pop(context); // close dialog
                  } else {
                    setState(() {
                      hasError = true; // 🔴 show error
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
