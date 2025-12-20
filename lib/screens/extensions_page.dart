import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/models/theme_provider.dart';
import 'package:provider/provider.dart';

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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final success = await context
                        .read<ExtensionServices>()
                        .addExtensionFromUrl(textController.text);

                    if (success == true) {
                      Navigator.pop(context);
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

  void deletExtension(
    Extension extension,
    ExtensionServices extensionServices,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return AlertDialog(
          title: Text('Delete extension', style: theme.textTheme.titleLarge),
          content: Text(
            'Are you sure you wanna delete ${extension.name}?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colors.onSurface)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                extensionServices.deleteExtension(extension.id);
                // delete logic
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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

    List<Extension> Extensions = extensionServices.currentExtensions;

    return Scaffold(
      appBar: AppBar(
        title: Text("Extension Page"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(.1),
          child: Divider(height: .1),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'edit_extension',
            onPressed: _setMainExtension,
            child: Icon(isEditingMainExtension ? Icons.check : Icons.edit),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add_extension',
            onPressed: _addExtension,
            child: Icon(Icons.add),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsetsGeometry.all(8),
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final extension = Extensions[index];
            return GestureDetector(
              onLongPress: () => deletExtension(extension, extensionServices),
              child: Container(
                decoration: BoxDecoration(
                  color: Provider.of<ThemeProvider>(context).scheme.onSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 100,
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    top: 8,
                    left: 8,
                    right: 24,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl:
                                extension.iconUrl ??
                                "https://cdn-icons-png.flaticon.com/512/8114/8114406.png",
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
                                  color: Provider.of<ThemeProvider>(
                                    context,
                                  ).scheme.secondary,
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
                                  color: Provider.of<ThemeProvider>(
                                    context,
                                  ).scheme.secondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      isEditingMainExtension
                          ? Checkbox(
                              value: extension.isMain,
                              onChanged: (isMain) async {
                                await extensionServices.setMainExtension(
                                  extension,
                                );
                                setState(() {});
                              },
                            )
                          : extension.isMain
                          ? Icon(Icons.check)
                          : Container(),
                    ],
                  ),
                ),
              ),
            );
          },
          itemCount: Extensions.length,
        ),
      ),
    );
  }
}
