import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/models/login_provider.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:metia/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:metia/models/logger.dart';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage> {
  final textController = TextEditingController();
  bool isEditingMainExtension = false;

  void _addExtension() {
    showDialog(
      context: context,
      builder: (context) {
        textController.clear();
        bool hasError = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add extension'),
              content: TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Extension URL',
                  errorText: hasError ? 'Invalid or unreachable URL' : null,
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final success = await context.read<ExtensionServices>().addExtensionFromUrl(textController.text);

                    if (success == true) {
                      Navigator.pop(context);
                      final token = Provider.of<UserProvider>(context, listen: false).JWTtoken;
                      if (token != null) {
                        Provider.of<SyncService>(context, listen: false).sync(token);
                      }
                    } else {
                      setState(() {
                        hasError = true; // 🔴 turns TextField red
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

  void readExtensions() {
    // context.watch<ExtensionServices>().getExtensions();
  }

  Future<bool> deletExtension(Extension extension, ExtensionServices extensionServices) async {
    final isMain = extension.isMain == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return AlertDialog(
          title: Text('Delete extension', style: theme.textTheme.titleLarge),
          content: Text(
            isMain
                ? '“${extension.name}” is the main extension.\n\n'
                      'If you delete it, the first extension in the list '
                      'will automatically become the main extension.'
                : 'Are you sure you wanna delete ${extension.name}?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
              onPressed: () async {
                await extensionServices.deleteExtension(extension.id);
                String token = Provider.of<UserProvider>(context, listen: false).JWTtoken!;
                await Provider.of<SyncService>(
                  context,
                  listen: false,
                ).deleteFromServer(token, "extension", extension.id.toString());
                Logger.log("WARNING: Deleted \"${extension.name} with id:${extension.id} from the server\"");
                // 👇 If main was deleted, reassign
                if (isMain) {
                  final remaining = extensionServices.currentExtensions;

                  if (remaining.isNotEmpty) {
                    await extensionServices.setMainExtension(remaining.first);
                  }
                }

                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _setMainExtension() {
    if (isEditingMainExtension) {
      setState(() {
        isEditingMainExtension = false;
      });
    } else {
      setState(() {
        isEditingMainExtension = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extensionServices = context.watch<ExtensionServices>();

    List<Extension> extensions = extensionServices.currentExtensions;

    return Scaffold(
      appBar: AppBar(
        title: Text("Extension Page"),
        bottom: PreferredSize(preferredSize: Size.fromHeight(.1), child: Divider(height: .1)),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extensions.length > 1)
            FilledButton.tonalIcon(
              icon: Icon(isEditingMainExtension ? Icons.check : Icons.edit),
              label: Text(isEditingMainExtension ? "Apply" : "Edit"),
              onPressed: _setMainExtension,
            ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: "add_extension",
            icon: const Icon(Icons.add),
            label: const Text("Add"),
            onPressed: _addExtension,
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsetsGeometry.all(8),
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final extension = extensions[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Dismissible(
                key: ValueKey(extension.id),
                direction: DismissDirection.endToStart,

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Theme.of(context).colorScheme.error,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      Text(
                        "Delete",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                    ],
                  ),
                ),
                confirmDismiss: (_) => deletExtension(extension, extensionServices),
                onDismissed: (_) {},
                child: Container(
                  color: Provider.of<ThemeProvider>(context).scheme.onSecondary,
                  height: 100,
                  child: Padding(
                    padding: EdgeInsetsGeometry.only(top: 8, left: 8, right: 24, bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: extension.iconUrl ?? "https://cdn-icons-png.flaticon.com/512/8114/8114406.png",
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  extension.name ?? "Broken Extension",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Author: ${extension.author ?? "Broken Extension"}",
                                  style: TextStyle(
                                    color: Provider.of<ThemeProvider>(context).scheme.secondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "${extension.language} - ${(extension.isDub ?? false) & (extension.isSub ?? false)
                                      ? "Dub | Sub"
                                      : (extension.isSub ?? false)
                                      ? "Sub"
                                      : (extension.isDub ?? false)
                                      ? "Dub"
                                      : "not specified"}",
                                  style: TextStyle(
                                    color: Provider.of<ThemeProvider>(context).scheme.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Checkbox(
                          value: extension.isMain,
                          onChanged: isEditingMainExtension
                              ? (isMain) async {
                                  await extensionServices.setMainExtension(extension);
                                  setState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          itemCount: extensions.length,
        ),
      ),
    );
  }
}
