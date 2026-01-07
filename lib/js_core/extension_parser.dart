import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/models/logger.dart';

class ExtensionParser {
  static Future<Extension> parse(String extensionLink) async {
    try {
      final uri = Uri.parse(extensionLink);

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch extension JSON');
      }

      final json = jsonDecode(response.body);

      if (json['jsCodeUrl'] == null) {
        throw FormatException('Missing jsCodeUrl');
      }

      final jsRes = await http.get(Uri.parse(json['jsCodeUrl']));
      if (jsRes.statusCode != 200) {
        throw Exception('Failed to fetch JS code');
      }

      final extension = Extension()
        ..name = json['name']
        ..iconUrl = json['iconUrl']
        ..isSub = json['isSub']
        ..isDub = json['isDub']
        ..language = json['language']
        ..anilistPreferedTitle = json['anilistPreferedTitle']
        ..jsCodeUrl = extensionLink
        ..jsCode = jsRes.body
        ..version = json['version']
        ..author = json['author']
        ..description = json['description'];

      return extension;
    } catch (e, stack) {
      Logger.log('Error parsing extension: $e');
      debugPrintStack(stackTrace: stack);

      // 🔥 IMPORTANT PART
      rethrow;
    }
  }
}
