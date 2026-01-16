import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/anilist/anime.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:metia/models/logger.dart';

class Tools {
  static Future<String> fetchAniListAccessToken(String authorizationCode) async {
    final Uri tokenEndpoint = Uri.https('anilist.co', '/api/v2/oauth/token');
    final Map<String, String> payload = {
      'grant_type': 'authorization_code',
      'client_id': '25588',
      'client_secret': 'QCzgwOKG6kJRzRL91evKRXXGfDCHlmgXfi44A0Ok',
      'redirect_uri': 'metia://',
      'code': authorizationCode,
    };

    try {
      final http.Response response = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['access_token'] as String;
      } else {
        throw Exception('Failed to retrieve access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // static void Toast(BuildContext context, String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Center(
  //         child: Text(
  //           message,
  //           style: const TextStyle(
  //             fontWeight: FontWeight.bold,
  //             color: MyColors.appbarTextColor,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ),
  //       duration: const Duration(seconds: 1),
  //       backgroundColor: MyColors.appbarColor,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     ),
  //   );
  // }

  static getResponsiveCrossAxisVal(double width, {required double itemWidth}) {
    return (width / itemWidth).round();
  }

  static String insertAt(String original, String toInsert, int index) {
    if (index < 0 || index > original.length) {
      throw ArgumentError("Index out of range");
    }
    return original.substring(0, index) + toInsert + original.substring(index);
  }

  static Future<bool> transferToAnotherList(MediaListEntry anime, BuildContext context, bool shouldPopOnceMore) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool isLoading = false;
        final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        return SizedBox(
          height: isLandscape ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.563,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                child: Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          final TextEditingController listNameController = TextEditingController();

                          return AlertDialog(
                            title: const Text('Create New Custom List'),
                            content: TextField(
                              controller: listNameController,
                              decoration: const InputDecoration(labelText: 'List Name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                onPressed: () async {
                                  final name = listNameController.text.trim();
                                  if (name.isEmpty) return;

                                  try {
                                    await Provider.of<UserProvider>(context, listen: false).createCustomList(name);

                                    await Provider.of<UserProvider>(context, listen: false).reloadUserData();

                                    Navigator.of(dialogContext).pop();
                                  } catch (_) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                  body: Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: isLoading,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                "Select the List:",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: Provider.of<UserProvider>(context).user.userLists.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final Map listDetails = Provider.of<UserProvider>(context).user.userLists[index];

                                    final bool isCurrent =
                                        listDetails["name"].toString().toLowerCase() ==
                                        anime.getGroup()!.name.toLowerCase();

                                    return SizedBox(
                                      height: 50,
                                      child: Opacity(
                                        opacity: isCurrent ? 0.5 : 1,
                                        child: ElevatedButton(
                                          onPressed: isCurrent
                                              ? null
                                              : () async {
                                                  try {
                                                    setModalState(() => isLoading = true);

                                                    await anime.getGroup()!.changeEntryStatus(
                                                      context,
                                                      anime,
                                                      listDetails["name"],
                                                      listDetails["isCustom"],
                                                    );

                                                    await Provider.of<UserProvider>(
                                                      context,
                                                      listen: false,
                                                    ).reloadUserData();

                                                    if (context.mounted) {
                                                      Navigator.of(context).pop(true); // ✅ SUCCESS
                                                    }

                                                    if (shouldPopOnceMore) {
                                                      Navigator.of(context).pop();
                                                    }
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      Navigator.of(context).pop(false); // ❌ ERROR
                                                    }
                                                  }
                                                },
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Text(
                                                  listDetails["name"],
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              if (isCurrent)
                                                const Align(alignment: Alignment.centerRight, child: Icon(Icons.check)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    // Swipe-down / back button / cancel → false
    return result ?? false;
  }

  static Future<void> updateAnimeTracking({
    required int mediaId,
    String? status, // e.g., "CURRENT", "COMPLETED"
    int? progress, // e.g., number of episodes watched
    double? score, // e.g., 8.5
    String? accessToken,
  }) async {
    const String url = 'https://graphql.anilist.co';

    const String mutation = r'''
      mutation($mediaId: Int, $status: MediaListStatus, $progress: Int, $score: Float) {
        SaveMediaListEntry(mediaId: $mediaId, status: $status, progress: $progress, score: $score) {
          id
          status
          progress
          score
        }
      }
    ''';

    final Map<String, dynamic> variables = {
      'mediaId': mediaId,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (score != null) 'score': score,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'query': mutation, 'variables': variables}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        Logger.log('AniList API Error: ${data['errors']}');
      } else {
        Logger.log('Tracking updated: ${data['data']['SaveMediaListEntry']}');
      }
    } else {
      Logger.log('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  static Future<String?> getServerJwtToken(String aniListToken) async {
    final String baseUrl = 'https://metiasync-supabase.vercel.app';
    // final String baseUrl = 'https://metiasync.onrender.com';

    final response = await http.post(
      Uri.parse('$baseUrl/auth/anilist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'anilist_auth_key': aniListToken}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['token']; // ✅ Server JWT token
    } else {
      Logger.log('Failed to get JWT: ${response.body}');
      return null;
    }
  }
}
