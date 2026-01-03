import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/isar_services/isar_services.dart';
import 'package:metia/js_core/extension_parser.dart';
import 'package:metia/models/logger.dart';

class ExtensionServices extends ChangeNotifier {
  static late final Isar db;

  static Future<void> setup() async {
    db = IsarServices.isar;
  }

  final List<Extension> currentExtensions = [];

  /// Adds an extension and optionally makes it main if none exists
  Future<void> addExtension(Extension extension) async {
    await db.writeTxn(() async {
      // If no main extension exists, make this one main
      final hasMain =
          await db.extensions.where().filter().isMainEqualTo(true).count() > 0;
      if (!hasMain) {
        extension.isMain = true;
      }
      if (currentExtensions.isEmpty) {
        extension.isMain = true;
      }
      extension.lastModified = DateTime.now(); // Set lastModified
      await db.extensions.put(extension);
    });
    await getExtensions();
    
  }

  /// Fetch all extensions and update local list
  Future<void> getExtensions() async {
    List<Extension> extensions = await db.extensions.where().findAll();
    currentExtensions.clear();
    currentExtensions.addAll(extensions);
    notifyListeners();
  }

  /// Delete an extension and transfer isMain if needed
  Future<void> deleteExtension(int id) async {
    await db.writeTxn(() async {
      // Find the extension to delete
      final extensionToDelete = await db.extensions.get(id);
      if (extensionToDelete == null) return;

      // Delete the extension
      await db.extensions.delete(id);


      // If it was the main extension, transfer isMain to the first available extension
      if (extensionToDelete.isMain) {
        final remainingExtensions = await db.extensions.where().findAll();
        if (remainingExtensions.isNotEmpty) {
          final firstExtension = remainingExtensions.first;
          firstExtension.isMain = true;
          firstExtension.lastModified = DateTime.now(); // Set lastModified
          await db.extensions.put(firstExtension);
        }
      }
    });

    // Refresh the local list
    await getExtensions();
  }

  /// Add extension from URL and return success
  Future<bool> addExtensionFromUrl(String url) async {
    try {
      Extension extension = await ExtensionParser.parse(url);
      await addExtension(extension);
      await Logger.log('Successfully added ${extension.name} to the database');
      return true;
    } catch (e) {
      await Logger.log(
        'Something went wrong whilst adding the extension, Error: ${e.toString()}',
      );
      return false;
    }
  }

  /// Set one extension as the main extension
  Future<void> setMainExtension(Extension extension) async {
    await db.writeTxn(() async {
      // Reset all other extensions
      final allExtensions = await db.extensions.where().findAll();
      for (var ext in allExtensions) {
        if (ext.id != extension.id && ext.isMain == true) {
          ext.isMain = false;
          ext.lastModified = DateTime.now(); // Set lastModified
          await db.extensions.put(ext);
        }
      }

      // Set the chosen extension as main
      extension.isMain = true;
      extension.lastModified = DateTime.now(); // Set lastModified
      await db.extensions.put(extension);
    });

    await getExtensions();
  }

  /// Get the current main extension
  Extension? get mainExtension {
    try {
      return currentExtensions.firstWhere((ext) => ext.isMain == true);
    } catch (e) {
      // If no main extension exists, return null
      return null;
    }
  }
}
