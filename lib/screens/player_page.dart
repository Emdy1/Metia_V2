import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

import 'package:flutter/services.dart';
import 'package:metia/data/extensions/extension_runtime_manager.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/data/user/user_library.dart';
import 'package:metia/js_core/anime.dart';
import 'package:metia/models/anime_database.dart';
import 'package:metia/models/episode_data_service.dart';
import 'package:metia/models/episode_database.dart';
import 'package:metia/models/episode_history_instance.dart';
import 'package:metia/models/episode_history_service.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/logger.dart';
import 'package:metia/services/sync_service.dart';
import 'package:metia/tools/general_tools.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import 'package:window_manager/window_manager.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.animeStreamingData,
    required this.mediaListEntry,
    required this.animeData,
    required this.episodeData,
    required this.episodeList,
  });

  final StreamingData animeStreamingData;
  final MediaListEntry mediaListEntry;
  final MetiaEpisode episodeData;
  final MetiaAnime animeData;
  final List<MetiaEpisode> episodeList;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  //late List<dynamic> episodeList = widget.episodeList;

  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  bool _isFullscreen = false;

  String totalTime = "00:00";
  String currentTime = "00:00";
  bool hasHours = false;

  Timer? _hideTimer;
  Timer? _seekTimer;
  Timer? _seekDisplayTimer;
  double? _dragValue;
  bool _hasSeeked = false;

  bool _showControls = true;
  bool _showSeekDisplay = false;
  int _seekSeconds = 0;
  DateTime? _lastDoubleTapTime;
  Offset? _lastTapPosition;

  bool firstTime = true;
  Timer? _positionSaveTimer;

  bool _isPlaying = true;

  bool _is2xRate = false;

  bool _isLoading = true;

  late int epIndex;
  late ExtensionServices extensionServices;
  late EpisodeDataService episodeDataService;
  late ExtensionRuntimeManager runtime;

  bool isGoingToAnotherEpisode = false;

  Duration parseDuration(String timeString) {
    final parts = timeString.split(':').map(int.parse).toList();

    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else {
      throw const FormatException("Invalid time format");
    }
  }

  String _formatDuration(Duration duration, {bool forceHours = false}) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0 || forceHours) {
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      // Change this line
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void nextEpisode() async {
    Logger.log("Loading Next Episode");
    int epIndex = widget.episodeList.indexWhere(
      (element) =>
          element == widget.episodeData, // compare by ID or unique property    //TODO: widget.episodeList[epIndex].url
    );

    runtime.executor!.getEpisodeStreamData(widget.episodeList[epIndex + 1].url).then((value) async {
      String accessToken = await Provider.of<UserProvider>(context, listen: false).getAuthKey();
      await Tools.updateAnimeTracking(
        mediaId: widget.mediaListEntry.media.id,
        progress: epIndex + 1,
        status: widget.mediaListEntry.media.episodes == epIndex ? "COMPLETED" : "CURRENT",
        accessToken: accessToken,
      );
      Provider.of<UserProvider>(context, listen: false).reloadUserData();

      isGoingToAnotherEpisode = true;

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(
            episodeList: widget.episodeList,
            animeStreamingData: value[0],
            mediaListEntry: widget.mediaListEntry,
            animeData: widget.animeData,
            episodeData:
                widget.episodeList[widget.episodeList.indexWhere(
                      (element) => element == widget.episodeData, // compare by ID or unique property
                    ) +
                    1],
          ),
        ),
      );
    });
  }

  void pastEpisode() {
    Logger.log("Loading Past Episode");
    int epIndex = widget.episodeList.indexWhere(
      (element) =>
          element == widget.episodeData, // compare by ID or unique property    //TODO: widget.episodeList[epIndex].url
    );

    runtime.executor!.getEpisodeStreamData(widget.episodeList[epIndex - 1].url).then((value) async {
      String accessToken = await Provider.of<UserProvider>(context, listen: false).getAuthKey();
      await Tools.updateAnimeTracking(
        mediaId: widget.mediaListEntry.media.id,
        progress: epIndex + 1,
        status: widget.mediaListEntry.media.episodes == epIndex ? "COMPLETED" : "CURRENT",
        accessToken: accessToken,
      );
      Provider.of<UserProvider>(context, listen: false).reloadUserData();

      isGoingToAnotherEpisode = true;

      Navigator.pop(context);

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (context) => PlayerPage(
            episodeList: widget.episodeList,
            animeStreamingData: value[0],
            mediaListEntry: widget.mediaListEntry,
            animeData: widget.animeData,
            episodeData:
                widget.episodeList[widget.episodeList.indexWhere(
                      (element) => element == widget.episodeData, // compare by ID or unique property
                    ) -
                    1],
          ),
        ),
      );
    });
  }

  void _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
    }
  }

  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final token = Provider.of<UserProvider>(context, listen: false).JWTtoken;
        if (token != null) {
          Provider.of<SyncService>(context, listen: false).sync(token);
        }
      }
    });

    super.initState();
    extensionServices = Provider.of<ExtensionRuntimeManager>(context, listen: false).extensionServices;
    episodeDataService = Provider.of<EpisodeDataService>(context, listen: false);
    runtime = Provider.of<ExtensionRuntimeManager>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _setupEpisodeData());

    // Force landscape
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listeners
    player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() {
          hasHours = duration.inHours > 0;
          totalTime = _formatDuration(duration);
        });
      }
    });

    player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    player.stream.buffering.listen((isBuffering) {
      if (mounted) setState(() => _isLoading = isBuffering);
    });

    player.stream.position.listen((position) {
      if (mounted) {
        setState(() {
          currentTime = _formatDuration(position, forceHours: hasHours);
        });
      }
    });
  }

  Future<void> _setupEpisodeData() async {
    final historyService = Provider.of<EpisodeHistoryService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    epIndex = widget.episodeList.indexWhere((e) => e == widget.episodeData);
    if (epIndex == -1) epIndex = 0;

    // Add to history
    historyService.addEpisodeHistory(
      EpisodeHistoryInstance()
        ..episode = widget.episodeData
        ..title = widget.animeData.name
        ..episodeNumber = epIndex
        ..anilistMediaId = widget.mediaListEntry.media.id
        ..extensionId = runtime.extensionServices.mainExtension!.id
        ..seen = (widget.mediaListEntry.progress ?? 0) > epIndex
        ..parentList = widget.episodeList
        ..anime = widget.animeData
        ..lastModified = DateTime.now(),
    ); // Add this line

    if (mounted) {
      final token = Provider.of<UserProvider>(context, listen: false).JWTtoken;
      if (token != null) {
        Provider.of<SyncService>(context, listen: false).sync(token);
      }
    }

    // Get or create episode progress data
    final currentExtensionId = extensionServices.mainExtension!.id;
    EpisodeData? epData = await episodeDataService.getEpisodeDataOf(
      widget.mediaListEntry.media.id,
      currentExtensionId,
      epIndex,
    );

    if (epData == null) {
      epData = EpisodeData()
        ..anilistMediaId = widget.mediaListEntry.media.id
        ..extensionId = currentExtensionId
        ..index = epIndex
        ..progress = 0
        ..total = 0;
      epData.lastModified = DateTime.now(); // Add this line
      await episodeDataService.addEpisodeData(epData);
      // Re-fetch to ensure we have the Isar-managed instance
      epData = await episodeDataService.getEpisodeDataOf(widget.mediaListEntry.media.id, currentExtensionId, epIndex);
    }

    if (epData == null) return; // Should not happen

    // Start player
    await initPlayer(true, "", epData);

    // Listen to player position to update progress
    player.stream.position.listen((position) {
      if (!_hasSeeked) return; // Ignore until initial seek is done

      episodeDataService.updateEpisodeProgress(
        episode: epData,
        progress: position.inMilliseconds,
        total: player.state.duration.inMilliseconds,
      );

      // Update Anilist tracking near the end
      if (userProvider.isLoggedIn &&
          player.state.duration.inSeconds > 0 &&
          position.inSeconds >= player.state.duration.inSeconds - 120) {
        if (firstTime) {
          firstTime = false;
          if ((widget.mediaListEntry.progress ?? 0) < epIndex + 1) {
            userProvider.getAuthKey().then((accessToken) {
              Tools.updateAnimeTracking(
                mediaId: widget.mediaListEntry.media.id,
                progress: epIndex + 1,
                status: widget.mediaListEntry.media.episodes == epIndex + 1 ? "COMPLETED" : "CURRENT",
                accessToken: accessToken,
              );
            });
          }
        }
      }
    });
  }

  Future<void> initPlayer(bool useDefaultLink, String m3u8, EpisodeData epData) async {
    String m3u8Link = useDefaultLink ? widget.animeStreamingData.m3u8Link : m3u8;
    Logger.log("playing with: ${m3u8Link}");
    await player.open(
      Media(
        m3u8Link,
        httpHeaders: {
          "referer": widget.animeStreamingData.link,
          "user-agents":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
        },
      ),
      play: true,
    );

    // Seek to last known position
    if (epData.progress != null && epData.progress! > 0) {
      // Defer seeking until the player is ready
      late StreamSubscription sub;
      sub = player.stream.position.listen((duration) async {
        if (duration.inMilliseconds > 200) {
          await player.seek(Duration(milliseconds: epData.progress!.toInt()));
          _hasSeeked = true; // Mark that we have seeked
          if (mounted) setState(() => _isLoading = false);
          await sub.cancel();
        }
      });
    } else {
      _hasSeeked = true; // No seek needed
    }

    _startHideTimer();
  }

  void handleKeboardShortcuts(event) {
    if (event is RawKeyDownEvent) {
      // Spacebar: Play/Pause
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (player.state.playing) {
          player.pause();
        } else {
          player.play();
        }
      }
      // Left Arrow: Seek backward 10 seconds
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.seek(player.state.position - const Duration(seconds: 10));
      }
      // Right Arrow: Seek forward 10 seconds
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.seek(player.state.position + const Duration(seconds: 10));
      }
      if (event.logicalKey == LogicalKeyboardKey.f12) {
        if (_isFullscreen) {
          windowManager.setFullScreen(true);
        } else {
          windowManager.setFullScreen(false);
        }
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekTimer?.cancel();

    _seekDisplayTimer?.cancel();
    // Restore your app's normal orientations when leaving this page
    if (!isGoingToAnotherEpisode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    player.dispose();

    super.dispose();
  }

  void onLongPressStarted(details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx > screenWidth / 2;
    if (isLeftSide) {
      player.setRate(2.0);
      _is2xRate = true;
    }
  }

  void onLongPressEnds() {
    player.setRate(1.0);
    _is2xRate = false;
  }

  void onDoubleTapDown(details) {
    _lastTapPosition = details.globalPosition;
  }

  void onDoubleTap() {
    if (_lastTapPosition == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = _lastTapPosition!.dx < screenWidth / 2;

    final now = DateTime.now();
    if (_lastDoubleTapTime != null && now.difference(_lastDoubleTapTime!).inSeconds <= 1) {
      setState(() {
        _seekSeconds += isLeftSide ? -10 : 10;
      });
    } else {
      setState(() {
        _seekSeconds = isLeftSide ? -10 : 10;
      });
    }
    _lastDoubleTapTime = now;

    player.seek(player.state.position + Duration(seconds: isLeftSide ? -10 : 10));

    setState(() {
      _showSeekDisplay = true;
    });

    // If controls are visible, reset the hide timer
    if (_showControls) {
      _startHideTimer();
    }

    _seekDisplayTimer?.cancel();
    _seekDisplayTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSeekDisplay = false;
        });
        // Reset the seek seconds after the fade animation is complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _seekSeconds = 0;
            });
          }
        });
      }
    });
  }

  void onTap() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  Widget buildDoubleTapSeeker() {
    return Positioned(
      left: _seekSeconds < 0
          ? MediaQuery.of(context).size.width * 0.25 -
                50 // Subtract half of approximate container width
          : MediaQuery.of(context).size.width * 0.75 - 50, // Subtract half of approximate container width
      top: MediaQuery.of(context).size.height * 0.5 - 25, // Subtract half of approximate container height
      child: AnimatedOpacity(
        opacity: _showSeekDisplay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
          child: Text(
            '${_seekSeconds > 0 ? "+" : ""}${_seekSeconds}s',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget buildDoubleSpeedIndicator() {
    return Positioned(
      left: _seekSeconds < 0
          ? MediaQuery.of(context).size.width * 0.25 -
                50 // Subtract half of approximate container width
          : MediaQuery.of(context).size.width * 0.75 - 50, // Subtract half of approximate container width
      top: MediaQuery.of(context).size.height * 0.5 - 25, // Subtract half of approximate container height
      child: AnimatedOpacity(
        opacity: _is2xRate ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            "2X speed",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget buildPlayerFade() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85), // Top
            Colors.transparent, // Just above middle
            Colors.transparent, // Just below middle
            Colors.black.withOpacity(0.85), // Bottom
          ],
          stops: const [
            0.0, // Top
            0.45, // Fade to transparent
            0.55, // Stay transparent
            1.0, // Fade back to black
          ],
        ),
      ),
    );
  }

  Widget buildPlayerControls() {
    return AnimatedSwitcher(
      reverseDuration: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 300),
      child: _showControls
          ? Stack(
              children: [
                buildPlayerFade(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //top  => back icon, title. done
                    Container(
                      //height: MediaQuery.of(context).size.height * 0.3,
                      width: double.maxFinite,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop("setState");
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.38),
                            ),
                          ),
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mediaListEntry.media.title.english!,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.episodeData.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.38),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    //middle => play, pause, next episode, past episode. done
                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 40,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: IconButton(
                                  onPressed: epIndex == 0
                                      ? null
                                      : () {
                                          _startHideTimer();
                                          pastEpisode();
                                        },
                                  icon: Icon(
                                    Icons.arrow_back,
                                    size: 40,
                                    color: epIndex == 0 ? const Color.fromARGB(255, 51, 50, 51) : Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (player.state.playing) {
                                      player.pause();
                                    } else {
                                      player.play();
                                    }
                                  },
                                  icon: Icon(
                                    player.state.playing ? Icons.pause : Icons.play_arrow,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: IconButton(
                                  onPressed: (epIndex + 1) == widget.animeData.length
                                      ? null
                                      : () {
                                          nextEpisode();
                                          _startHideTimer();
                                        },
                                  icon: Icon(
                                    Icons.arrow_forward,
                                    size: 40,
                                    color: (epIndex + 1) == widget.animeData.length
                                        ? const Color.fromARGB(255, 51, 50, 51)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isLoading) CircularProgressIndicator(),
                    //bottom => current time, seekbar, duration
                    Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Text(
                              currentTime,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            // ...inside your build method...
                            Expanded(
                              child: SizedBox(
                                height: 30,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Buffering bar (background)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          // Buffered progress
                                          FractionallySizedBox(
                                            widthFactor: player.state.duration.inSeconds == 0
                                                ? 0
                                                : player.state.buffer.inSeconds / player.state.duration.inSeconds,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          // Playback progress (white)
                                          // Playback progress (white)
                                          FractionallySizedBox(
                                            widthFactor: player.state.duration.inSeconds == 0
                                                ? 0
                                                : (_dragValue ?? player.state.position.inSeconds.toDouble()) /
                                                      player.state.duration.inSeconds,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),

                                          // Slider thumb (interactive)
                                        ],
                                      ),
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 0,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        activeTrackColor: Colors.transparent,
                                        inactiveTrackColor: Colors.transparent,
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: player.state.duration.inSeconds.toDouble(),
                                        value:
                                            _dragValue ??
                                            player.state.position.inSeconds.toDouble().clamp(
                                              0,
                                              player.state.duration.inSeconds.toDouble(),
                                            ),
                                        onChanged: (value) {
                                          _startHideTimer();
                                          setState(() {
                                            _dragValue = value;
                                          });
                                        },
                                        onChangeEnd: (value) {
                                          setState(() {
                                            _dragValue = null;
                                          });
                                          player.seek(Duration(seconds: value.toInt()));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              totalTime,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            !(Platform.isIOS || Platform.isAndroid)
                                ? IconButton(
                                    icon: Icon(
                                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    onPressed: _toggleFullscreen,
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const SizedBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKey: (RawKeyEvent event) async {
            handleKeboardShortcuts(event);
          },
          child: Stack(
            children: [
              Video(
                controller: controller,
                aspectRatio: 16.0 / 9.0,
                controls: (state) {
                  return GestureDetector(
                    onLongPressStart: (details) {
                      onLongPressStarted(details);
                    },
                    onLongPressEnd: (details) {
                      onLongPressEnds();
                    },
                    onDoubleTapDown: (details) {
                      onDoubleTapDown(details);
                    },
                    onDoubleTap: () {
                      onDoubleTap();
                    },
                    onTap: () {
                      onTap();
                    },
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          Container(
                            // This transparent container ensures the GestureDetector covers the full area
                            color: Colors.transparent,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // Seek indicator with fade animation
                          buildDoubleTapSeeker(),
                          buildDoubleSpeedIndicator(),
                          buildPlayerControls(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
