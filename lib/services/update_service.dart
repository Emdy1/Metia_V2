import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:metia/models/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoOwner = 'Emdy1';
  static const String _repoName = 'Metia_V2';
  static const String _githubApiLatestRelease = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final currentVersion = await _getCurrentAppVersion();
      final latestRelease = await _getLatestRelease();

      if (latestRelease == null) {
        // No releases found or API error, log and return
        return;
      }

      final latestVersion = _parseVersion(latestRelease['tag_name']);
      final changelog = latestRelease['body'];
      final downloadUrl = _getDownloadUrl(latestRelease['assets']);

      if (downloadUrl == null) {
        // No suitable asset found, log and return
        return;
      }

      if (_isNewVersionAvailable(currentVersion, latestVersion)) {
        _showUpdateDialog(context, changelog, downloadUrl, latestVersion);
      } else {
        Logger.log("INFO: the app is Up To Data, with the GITHUB repo");
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  Future<String> _getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map<String, dynamic>?> _getLatestRelease() async {
    final response = await http.get(
      Uri.parse(_githubApiLatestRelease),
      headers: {'User-Agent': 'Metia_V2_App', 'Accept': 'application/vnd.github.v3+json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch latest release: ${response.statusCode}');
      return null;
    }
  }

  String _parseVersion(String tagName) {
    // Strip leading "v" if present
    if (tagName.startsWith('v')) {
      return tagName.substring(1);
    }
    return tagName;
  }

  bool _isNewVersionAvailable(String currentVersion, String latestVersion) {
    final current = currentVersion.split('.').map(int.parse).toList();
    final latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latest.length; i++) {
      if (i >= current.length || latest[i] > current[i]) {
        return true;
      }
      if (latest[i] < current[i]) {
        return false;
      }
    }
    return false; // Versions are the same
  }

  String getAndroidAbi() {
    if (!Platform.isAndroid) return 'unknown';

    // You can use Platform.version, it contains the JVM ABI info
    final versionInfo = Platform.version.toLowerCase();

    if (versionInfo.contains('arm64')) return 'arm64-v8a';
    if (versionInfo.contains('armeabi')) return 'armeabi-v7a';
    if (versionInfo.contains('x86_64')) return 'x86_64';
    if (versionInfo.contains('x86')) return 'x86';
    if (versionInfo.contains('android_x64')) return 'x86_64';

    // fallback to popular abi
    return 'arm64-v8a';
  }

  String? _getDownloadUrl(List<dynamic> assets) {
    String? url;
    if (Platform.isAndroid) {
      List apks = assets.where((asset) => asset['name'].endsWith('.apk')).toList();
      String abi = getAndroidAbi();
      url = apks.where((apk) => apk["name"].contains(abi)).first["browser_download_url"];
      print(url);
    } else if (Platform.isIOS) {
      // For iOS, typically we'd link to the App Store.
      // If direct IPA download is intended, the user needs to host it.
      // For now, assuming a direct download if available or provide a placeholder.
      url = assets.firstWhereOrNull((asset) => asset['name'].endsWith('.ipa'))?['browser_download_url'];
      // Fallback or specific App Store link can be added here.
      if (url == null) {
        print('Warning: No .ipa found for iOS. Consider linking to App Store.');
        // Example for App Store link (replace with actual app ID)
        // return 'https://apps.apple.com/app/idYOUR_APP_ID';
      }
    }
    return url;
  }

  void _showUpdateDialog(BuildContext context, String? changelog, String downloadUrl, String latestVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        elevation: 6,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Text(
          'Update Available!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$latestVersion is available to install!', style: Theme.of(context).textTheme.bodyLarge),
              if (changelog != null && changelog.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Changelog',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: Markdown(
                      padding: EdgeInsets.only(top: 4, left: 4, right: 4),
                      data: changelog,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.bodyMedium,
                        h3: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl(downloadUrl);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
      // Optionally show an error to the user
    }
  }
}

// Extension to mimic firstWhereOrNull for older Dart versions if needed, or if not imported
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
