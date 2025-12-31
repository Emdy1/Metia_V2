import 'dart:convert';

import 'package:flutter/material.dart' hide Title;
import 'package:metia/anilist/anime.dart';
import 'package:metia/data/user/credentials.dart';
import 'package:metia/data/user/profile.dart';
import 'package:metia/data/user/user_data.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class UserProvider extends ChangeNotifier {
  bool hasNextPage = true;

  String authKey = "";
  String _JWTtoken = "";
  String? get JWTtoken => _JWTtoken;

  bool get isMetiaSyncready => _isMetiaSyncReady;

  bool _isMetiaSyncReady = false;

  bool _isLoggedIn = false;

  Profile _user = Profile(
    explorerContent: [[], [], [], [], []],

    userLists: [],

    userActivityPage: ActivityPage(
      pageInfo: PageInfo(total: 0, perPage: 0, currentPage: 0, lastPage: 0, hasNextPage: false),

      activities: [],
    ),

    name: "Default",

    avatarLink: "https://s4.anilist.co/file/anilistcdn/user/avatar/large/default.png",

    bannerImage: "",

    id: 0,

    userLibrary: UserLibrary(library: []),

    statistics: Statistics(),
  );

  int _currentActivityPage = 1;

  bool _isLoadingMoreActivities = false;

  bool get isLoggedIn => _isLoggedIn;

  Profile get user => _user;

  List<UserActivity> get userActivities => _user.userActivityPage.activities;

  List<List<Media>> defaultExplorerContent = [[], [], [], [], []];

  bool isLoadingDefaultExplorerContent = false;

  bool isLoadingExplorerContent = false;

  List<Media> _searchResults = [];

  List<Media> get searchResults => _searchResults;

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  Set<int> _libraryMediaIds = {};

  bool isMediaInLibrary(int mediaId) => _libraryMediaIds.contains(mediaId);

  UserProvider() {
    _initializeLoginState();

    _loadDefaultExplorerContent();
  }

  Future<void> searchAnime(String keyword) async {
    _isSearching = true;

    _searchResults.clear();

    notifyListeners();

    _searchResults = await _anilistSearch(keyword);

    _isSearching = false;

    notifyListeners();
  }

  void _loadDefaultExplorerContent() async {
    isLoadingDefaultExplorerContent = true;

    defaultExplorerContent = await getDefaultExplorerContent();

    isLoadingDefaultExplorerContent = false;

    notifyListeners();
  }

  void logIn(String authKey) async {
    await UserData.saveAuthKey(authKey);
    Logger.log('Saved auth key of the user', level: 'INFO');

    await _getUserData();
    Logger.log('got user data with the name of ${user.name}', level: 'INFO');
    _isLoggedIn = true;
    notifyListeners();
    Logger.log('Notified the listening build methods to rebuild the app', level: 'INFO');
  }

  void logOut() {
    _isLoggedIn = false;

    UserData.deletAuthKey();
    notifyListeners();
  }

  Future<ActivityPage> _fetchUserActivities(int userId, int page, int perPage) async {
    const String url = 'https://graphql.anilist.co';

    final query = '''
    query (\$id: Int, \$type: ActivityType, \$page: Int, \$perPage: Int, ) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          perPage
          currentPage
          lastPage
          hasNextPage
        }
        activities(userId: \$id, type: \$type, sort: [PINNED, ID_DESC]) {
          ... on ListActivity {
            type
            status
            progress
            likeCount
            createdAt
            media {
              id
              type
              status(version: 2)
              isAdult
              bannerImage
              description
              genres
              title {
                english
                romaji
                native
              }
              episodes
              averageScore
              season
              seasonYear
              coverImage {
                large
                extraLarge
                medium
                color
              }
              duration
              nextAiringEpisode {
                airingAt
                episode
              }
            }
          }
        }
      }
    }
  ''';

    final variables = {"id": userId, "type": "ANIME_LIST", "page": page, "perPage": perPage};

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey'},
      body: jsonEncode({"query": query, "variables": variables}),
    );

    final data = jsonDecode(response.body)['data']['Page'];
    var src = ActivityPage.fromJson(data);
    return src;
  }

  Future<void> loadMoreActivities() async {
    if (_isLoadingMoreActivities) return; // prevent duplicate loads

    _isLoadingMoreActivities = true;
    _currentActivityPage++;

    try {
      ActivityPage newPage = await _fetchUserActivities(_user.id, _currentActivityPage, 20);

      hasNextPage = newPage.pageInfo.hasNextPage;

      // Append new activities to existing list
      _user.userActivityPage.activities.addAll(newPage.activities);
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoadingMoreActivities = false;
    }
  }

  Future<String> getAuthKey() async {
    return _getAuthKey();
  }

  Future<String> _getAuthKey() async {
    return await UserData.getAuthKey();
  }

  Future<void> reloadUserData() async {
    isLoadingExplorerContent = true;

    await _getUserData();
    isLoadingExplorerContent = false;

    notifyListeners();
  }

  Future<void> _getUserData() async {
    String authKey = await _getAuthKey();

    Tools.getServerJwtToken(authKey).then((value) {
      _JWTtoken = value!;
      _isMetiaSyncReady = true;
    });

    const String url = 'https://graphql.anilist.co';

    // Step 1: Query Viewer for user info + ID
    const String viewerQuery = '''
    query {
      Viewer {
        mediaListOptions {
          animeList {
            customLists
          }
        }
        id
        name
        avatar {
          large
        }
        bannerImage
        statistics {
          anime {
            count
            episodesWatched
            minutesWatched
          }
        }
      }
    }
  ''';

    final viewerResponse = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'},
      body: jsonEncode({'query': viewerQuery}),
    );

    final Map<String, dynamic> viewerData = jsonDecode(viewerResponse.body);

    if (viewerData['errors'] != null) {
      // handle error, e.g. throw or return early
      debugPrint('Error fetching viewer: ${viewerData['errors']}');
      return;
    }

    final viewer = viewerData['data']['Viewer'];
    final int userId = viewer['id'];

    // Step 2: Query MediaListCollection with userId
    const String mediaListQuery = '''
          query (
        \$type: MediaType!,
        \$userId: Int!,
        \$season: MediaSeason,
        \$seasonYear: Int,
        \$nextSeason: MediaSeason,
        \$nextYear: Int
      ) {
        MediaListCollection(type: \$type, userId: \$userId) {
          lists {
            name
            entries {
              id
              progress
              status
              media {
                id
                type
                status(version: 2)
                isAdult
                bannerImage
                description
                genres
                title {
                  english
                  romaji
                  native
                }
                episodes
                averageScore
                season
                seasonYear
                coverImage {
                  large
                  extraLarge
                  medium
                  color
                }
                duration
                nextAiringEpisode {
                  airingAt
                  episode
                }
              }
            }
          }
        }

        trending: Page(page: 1, perPage: 99) {
          media(sort: TRENDING_DESC, type: ANIME, isAdult: false) {
            ...mediaFields
          }
        }
        season: Page(page: 1, perPage: 99) {
          media(season: \$season, seasonYear: \$seasonYear, sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
            ...mediaFields
          }
        }
        nextSeason: Page(page: 1, perPage: 99) {
          media(season: \$nextSeason, seasonYear: \$nextYear, sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
            ...mediaFields
          }
        }
        popular: Page(page: 1, perPage: 99) {
          media(sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
            ...mediaFields
          }
        }
        top: Page(page: 1, perPage: 100) {
          media(sort: SCORE_DESC, type: ANIME, isAdult: false) {
            ...mediaFields
          }
        }
      }

      fragment mediaFields on Media {
        id
                type
                status(version: 2)
                isAdult
                bannerImage
                description
                genres
                title {
                  english
                  romaji
                  native
                }
                episodes
                averageScore
                season
                seasonYear
                coverImage {
                  large
                  extraLarge
                  medium
                  color
                }
                duration
                nextAiringEpisode {
                  airingAt
                  episode
                }
      }

  ''';

    final mediaListResponse = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'},
      body: jsonEncode({
        'query': mediaListQuery,
        'variables': {
          'type': 'ANIME',
          'userId': userId,
          "season": "FALL",
          "seasonYear": 2025,
          "nextSeason": "WINTER",
          "nextYear": 2026,
        },
      }),
    );

    final Map<String, dynamic> mediaListData = jsonDecode(mediaListResponse.body);

    if (mediaListData['errors'] != null) {
      debugPrint('Error fetching media list: ${mediaListData['errors']}');
      return;
    }

    final mediaListGroups = mediaListData['data']['MediaListCollection']['lists'] as List;

    // Parse media list groups
    List<MediaListGroup> parsedGroups = mediaListGroups.map((group) {
      // Step 1: Create the MediaListGroup first with empty entries
      final mediaListGroup = MediaListGroup(
        color: group['name'] == "Watching" ? Colors.green : Colors.white,
        isInteractive: group['name'] != "Airing",
        name: group['name'],
        entries: [], // will fill this next
        isCustom: !['Watching', 'Planning', 'Completed', 'Paused', 'Dropped'].contains(group['name']),
      );

      // Step 2: Fill in the entries and set the group reference
      List<MediaListEntry> entries = (group['entries'] as List).map((entry) {
        final mediaJson = entry['media'];
        var mediaListEntry = MediaListEntry(
          id: entry['id'],
          progress: entry['progress'],
          status: entry['status'],
          media: Media.fromJson(mediaJson),
        );

        // Use your setGroup() method
        mediaListEntry.setGroup(mediaListGroup);

        return mediaListEntry;
      }).toList();

      // Step 3: Add entries to the group
      mediaListGroup.entries.addAll(entries);

      return mediaListGroup; // ✅ return the filled group
    }).toList();

    //Step 1: Create the Airing group early (empty for now)
    final airingGroup = MediaListGroup(
      color: Colors.orange,
      name: "Airing",
      entries: [],
      isInteractive: false,
      isCustom: false,
    );

    // Step 2: Extract "airing" entries and reassign their group
    for (final group in parsedGroups) {
      if (["Planning", "Watching"].contains(group.name)) {
        for (final entry in group.entries) {
          final media = entry.media;
          final nextEp = media.nextAiringEpisode;

          if (nextEp != null && nextEp.episode > (entry.progress ?? 0) + 1) {
            // Reassign entry to airing group
            MediaListEntry newEntry = MediaListEntry(
              id: entry.id,
              progress: entry.progress,
              status: entry.status,
              media: media,
            );
            newEntry.setGroup(airingGroup);
            airingGroup.entries.add(newEntry);
          }
        }
      }
    }

    // Step 3: Insert the airing group at the beginning
    if (airingGroup.entries.isNotEmpty) {
      parsedGroups.insert(0, airingGroup);
    }

    const desiredOrder = ["Airing", "Watching", "Planning", "Completed", "Paused", "Dropped"];

    parsedGroups.sort((a, b) {
      int indexA = desiredOrder.indexOf(a.name ?? "");
      int indexB = desiredOrder.indexOf(b.name ?? "");
      return indexA.compareTo(indexB);
    });

    // Fetch user activities as before
    ActivityPage activityPage = await _fetchUserActivities(userId, 1, 20);

    final customLists = List<String>.from(viewer['mediaListOptions']['animeList']['customLists']);

    final defaultLists = [
      {'name': 'Watching', 'isCustom': false},
      {'name': 'Planning', 'isCustom': false},
      {'name': 'Completed', 'isCustom': false},
      {'name': 'Dropped', 'isCustom': false},
      {'name': 'Paused', 'isCustom': false},
    ];

    final custom = customLists.map((name) => {'name': name, 'isCustom': true});

    final userList = [...defaultLists, ...custom];

    _libraryMediaIds = parsedGroups.expand((group) => group.entries).map((entry) => entry.media.id).toSet();

    // Assign your Profile object
    _user = Profile(
      explorerContent: [
        (mediaListData["data"]["trending"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
        (mediaListData["data"]["season"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
        (mediaListData["data"]["nextSeason"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
        (mediaListData["data"]["popular"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
        (mediaListData["data"]["top"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
      ],
      name: viewer["name"],
      avatarLink: viewer["avatar"]["large"],
      bannerImage: viewer["bannerImage"] ?? "null",
      id: userId,
      statistics: Statistics.fromJson(viewer["statistics"]["anime"]),
      userLibrary: UserLibrary(library: parsedGroups),
      userActivityPage: activityPage,
      userLists: userList,
    );
  }

  Future<void> _initializeLoginState() async {
    authKey = await _getAuthKey();
    _isLoggedIn = authKey != "empty";

    if (_isLoggedIn) {
      notifyListeners();
      await _getUserData();
    }

    notifyListeners();
  }

  Future<void> deleteCustomList(String listName) async {
    const String url = 'https://graphql.anilist.co';

    List userAnimeLists = user.userLists;

    List<String> userAnimeCustomLists = userAnimeLists
        .where((list) => list['isCustom'] == true)
        .map<String>((list) => list['name'] as String)
        .toList();

    userAnimeCustomLists.remove(listName);

    final Map<String, dynamic> body = {
      'query': '''
      mutation(\$animeListOptions: MediaListOptionsInput) {
        UpdateUser(animeListOptions: \$animeListOptions) {
          id
        }
      }
    ''',
      'variables': {
        'animeListOptions': {'customLists': userAnimeCustomLists},
      },
    };

    String authKey = await _getAuthKey();

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authKey}', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
    } else {
      print('Failed to add custom list: ${response.body}');
    }
  }

  Future<void> createCustomList(String newListName) async {
    const String url = 'https://graphql.anilist.co';

    List userAnimeLists = user.userLists;

    List<String> userAnimeCustomLists = userAnimeLists
        .where((list) => list['isCustom'] == true)
        .map<String>((list) => list['name'] as String)
        .toList();

    userAnimeCustomLists.add(newListName);

    final Map<String, dynamic> body = {
      'query': '''
      mutation(\$animeListOptions: MediaListOptionsInput) {
        UpdateUser(animeListOptions: \$animeListOptions) {
          id
        }
      }
    ''',
      'variables': {
        'animeListOptions': {'customLists': userAnimeCustomLists},
      },
    };

    String authKey = await _getAuthKey();

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authKey}', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
    } else {
      print('Failed to add custom list: ${response.body}');
    }
  }

  // logOut State

  Future<List<List<Media>>> getDefaultExplorerContent() async {
    const String url = 'https://graphql.anilist.co';

    // Step 2: Query MediaListCollection with userId
    const String discoverAnimeQuery = '''
query (
  \$season: MediaSeason,
  \$seasonYear: Int,
  \$nextSeason: MediaSeason,
  \$nextYear: Int
) {
  trending: Page(page: 1, perPage: 6) {
    media(sort: TRENDING_DESC, type: ANIME, isAdult: false) {
      ...mediaFields
    }
  }

  season: Page(page: 1, perPage: 6) {
    media(
      season: \$season,
      seasonYear: \$seasonYear,
      sort: POPULARITY_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...mediaFields
    }
  }

  nextSeason: Page(page: 1, perPage: 6) {
    media(
      season: \$nextSeason,
      seasonYear: \$nextYear,
      sort: POPULARITY_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...mediaFields
    }
  }

  popular: Page(page: 1, perPage: 6) {
    media(sort: POPULARITY_DESC, type: ANIME, isAdult: false) {
      ...mediaFields
    }
  }

  top: Page(page: 1, perPage: 10) {
    media(sort: SCORE_DESC, type: ANIME, isAdult: false) {
      ...mediaFields
    }
  }
}

fragment mediaFields on Media {
  id
  title {
    userPreferred
    english
    romaji
    native
  }
  coverImage {
    extraLarge
    large
    color
  }
  bannerImage
  season
  seasonYear
  description
  type
  format
  status(version: 2)
  episodes
  duration
  genres
  isAdult
  averageScore
  popularity
  nextAiringEpisode {
    airingAt
    timeUntilAiring
    episode
  }
  studios(isMain: true) {
    edges {
      isMain
      node {
        id
        name
      }
    }
  }
}
''';

    final mediaListResponse = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'query': discoverAnimeQuery,
        'variables': {'type': 'ANIME', 'season': 'FALL', 'seasonYear': 2025, 'nextSeason': 'WINTER', 'nextYear': 2026},
      }),
    );

    final Map<String, dynamic> mediaListData = jsonDecode(mediaListResponse.body);

    return [
      (mediaListData["data"]["trending"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
      (mediaListData["data"]["season"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
      (mediaListData["data"]["nextSeason"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
      (mediaListData["data"]["popular"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
      (mediaListData["data"]["top"]["media"] as List).map((entry) => Media.fromJson(entry)).toList(),
    ];
  }
}

Future<List<Media>> _anilistSearch(String keyword) async {
  const String url = 'https://graphql.anilist.co';

  const String query = r'''
query (
  $page: Int
  $id: Int
  $type: MediaType
  $isAdult: Boolean = false
  $search: String
  $format: [MediaFormat]
  $status: MediaStatus
  $countryOfOrigin: CountryCode
  $source: MediaSource
  $season: MediaSeason
  $seasonYear: Int
  $year: String
  $onList: Boolean
  $yearLesser: FuzzyDateInt
  $yearGreater: FuzzyDateInt
  $episodeLesser: Int
  $episodeGreater: Int
  $durationLesser: Int
  $durationGreater: Int
  $chapterLesser: Int
  $chapterGreater: Int
  $volumeLesser: Int
  $volumeGreater: Int
  $licensedBy: [Int]
  $isLicensed: Boolean
  $genres: [String]
  $excludedGenres: [String]
  $tags: [String]
  $excludedTags: [String]
  $minimumTagRank: Int
  $sort: [MediaSort] = [POPULARITY_DESC, SCORE_DESC]
) {
  Page(page: $page, perPage: 80) {
    pageInfo {
      hasNextPage
    }
    media(
      id: $id
      type: $type
      search: $search
      format_in: $format
      status: $status
      countryOfOrigin: $countryOfOrigin
      source: $source
      season: $season
      seasonYear: $seasonYear
      startDate_like: $year
      startDate_lesser: $yearLesser
      startDate_greater: $yearGreater
      episodes_lesser: $episodeLesser
      episodes_greater: $episodeGreater
      duration_lesser: $durationLesser
      duration_greater: $durationGreater
      chapters_lesser: $chapterLesser
      chapters_greater: $chapterGreater
      volumes_lesser: $volumeLesser
      volumes_greater: $volumeGreater
      licensedById_in: $licensedBy
      isLicensed: $isLicensed
      genre_in: $genres
      genre_not_in: $excludedGenres
      tag_in: $tags
      tag_not_in: $excludedTags
      minimumTagRank: $minimumTagRank
      onList: $onList
      sort: $sort
      isAdult: $isAdult
    ) {
      id
                type
                status(version: 2)
                isAdult
                bannerImage
                description
                genres
                title {
                  english
                  romaji
                  native
                }
                episodes
                averageScore
                season
                seasonYear
                coverImage {
                  large
                  extraLarge
                  medium
                  color
                }
                duration
                nextAiringEpisode {
                  airingAt
                  episode
                }
    }
  }
}

''';

  List<Media> results = [];
  int page = 1;
  bool hasNextPage = true;

  while (hasNextPage) {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {'page': page, 'search': keyword, 'type': 'ANIME', 'isAdult': false},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AniList request failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final pageData = data['data']['Page'];

    final List mediaList = pageData['media'] ?? [];
    results.addAll(mediaList.map((e) => Media.fromJson(e)));

    hasNextPage = pageData['pageInfo']['hasNextPage'] ?? false;
    page++;
  }

  return results;
}
