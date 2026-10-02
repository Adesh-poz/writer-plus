import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/reusables/writer_snack_bar.dart';
import 'package:writer_plus/services/file_service.dart';

class Helper {
  /// Get the color of the provided file type.
  ///
  /// By default, gives the app's primaryColor.
  static Color getFileTypeColor(String fileExt) {
    switch (fileExt.toLowerCase()) {
      // Markdown
      case 'md':
        return Colors.blue;

      // Plain Text
      case 'txt':
        return Colors.grey;

      // Rich Text
      case 'rtf':
        return Colors.amber;

      // Microsoft Word - Note: Not Being used
      case 'doc':
      case 'docx':
        return Colors.indigo;

      default:
        return Constants.primaryColor;
    }
  }

  /// Displays dialog to create a new folder.
  static Future<void> showCreateFolderDialog(
    BuildContext context,
    Directory parentDirectory,
    VoidCallback onSuccess,
  ) async {
    final textController = TextEditingController();

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'New Folder',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter folder name',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Constants.primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Constants.primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = textController.text.trim();
                if (input.isNotEmpty) {
                  Navigator.pop(context, input);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (folderName != null && folderName.isNotEmpty) {
      try {
        await FileService().createFolder(parentDirectory, folderName);
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          WriterSnackBar.show(
            context,
            'Failed to create folder: $e',
            isError: true,
          );
        }
      }
    }
  }

  /// Displays dialog to rename a file or folder.
  static Future<void> showRenameDialog(
    BuildContext context,
    AppFileSystemItem item,
    VoidCallback onSuccess,
  ) async {
    final textController = TextEditingController(text: item.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            item.isDirectory ? 'Rename Folder' : 'Rename File',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new name',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Constants.primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Constants.primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = textController.text.trim();
                if (input.isNotEmpty) {
                  Navigator.pop(context, input);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != item.name) {
      try {
        await FileService().renameEntity(item.entity, newName);
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          WriterSnackBar.show(context, 'Failed to rename: $e', isError: true);
        }
      }
    }
  }

  /// Displays confirmation dialog to delete a file or folder.
  static Future<void> showDeleteDialog(
    BuildContext context,
    AppFileSystemItem item,
    VoidCallback onSuccess,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Delete ${item.isDirectory ? 'Folder' : 'File'}?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FileService().deleteEntity(item.entity);
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          WriterSnackBar.show(context, 'Failed to delete: $e', isError: true);
        }
      }
    }
  }

  /// Displays a Google Files style hierarchical browser dialog/bottom sheet to move an item.
  static Future<void> showMoveToDialog(
    BuildContext context,
    AppFileSystemItem item,
    Directory rootDir,
    VoidCallback onSuccess,
  ) async {
    try {
      Directory currentDir = rootDir;
      final List<Directory> directoryHistory = [];

      final selectedFolder = await showModalBottomSheet<Directory>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<List<AppFileSystemItem>>(
                future: FileService().getDirectoryItems(currentDir),
                builder: (context, snapshot) {
                  final allItems = snapshot.data ?? [];
                  final subfolders = allItems.where((i) {
                    if (!i.isDirectory) return false;
                    if (item.isDirectory && i.path.startsWith(item.path)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  final isAtRoot = currentDir.path == rootDir.path;
                  final folderName = isAtRoot
                      ? 'Root (WriterPlus)'
                      : currentDir.path.split(Platform.pathSeparator).last;

                  return SafeArea(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Row(
                            children: [
                              if (!isAtRoot)
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.chevronLeft,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (directoryHistory.isNotEmpty) {
                                      setState(() {
                                        currentDir = directoryHistory
                                            .removeLast();
                                      });
                                    }
                                  },
                                )
                              else
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Move to "$folderName"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'New Folder',
                                icon: const FaIcon(
                                  FontAwesomeIcons.folderPlus,
                                  size: 18,
                                  color: Constants.primaryColor,
                                ),
                                onPressed: () async {
                                  await showCreateFolderDialog(
                                    context,
                                    currentDir,
                                    () {},
                                  );
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12),

                          // Subfolders list
                          Expanded(
                            child: subfolders.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text(
                                        'No subfolders here',
                                        style: TextStyle(color: Colors.white38),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: subfolders.length,
                                    itemBuilder: (context, index) {
                                      final sub = subfolders[index];
                                      return ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        leading: const FaIcon(
                                          FontAwesomeIcons.solidFolder,
                                          color: Constants.primaryColor,
                                          size: 20,
                                        ),
                                        title: Text(
                                          sub.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        trailing: const FaIcon(
                                          FontAwesomeIcons.chevronRight,
                                          size: 12,
                                          color: Colors.white38,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            directoryHistory.add(currentDir);
                                            currentDir = Directory(sub.path);
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Footer Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Constants.primaryColor,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, currentDir),
                                  child: const Text('Move here'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );

      if (selectedFolder != null) {
        await FileService().moveEntity(item.entity, selectedFolder);
        onSuccess();
      }
    } catch (e) {
      if (context.mounted) {
        WriterSnackBar.show(context, 'Failed to move item: $e', isError: true);
      }
    }
  }

  /// Out-of-app sharing functionality.
  static Future<void> handleShare(
    BuildContext context,
    AppFileSystemItem item,
  ) async {
    if (item.isDirectory) {
      WriterSnackBar.show(
        context,
        'Sharing folders is not supported.',
        isError: true,
      );
      return;
    }

    try {
      await FileService().shareFile(item.entity as File);
    } catch (e) {
      if (context.mounted) {
        WriterSnackBar.show(context, 'Failed to share file: $e', isError: true);
      }
    }
  }

  /// Displays metadata details dialog for file/folder.
  static Future<void> showDetailsDialog(
    BuildContext context,
    AppFileSystemItem item,
  ) async {
    int wordCount = 0;
    if (!item.isDirectory && item.entity is File) {
      final text = await FileService().readFile(item.entity as File);
      wordCount = FileService().calculateWordCount(text);
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(item.name, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                'Type',
                item.isDirectory ? 'Folder' : 'File (.${item.extension})',
              ),
              const SizedBox(height: 8),
              _detailRow('Location', item.path),
              const SizedBox(height: 8),
              _detailRow('Last Modified', item.formattedLastModified),
              if (!item.isDirectory) ...[
                const SizedBox(height: 8),
                _detailRow('Size', item.formattedSize),
                const SizedBox(height: 8),
                _detailRow('Word Count', '$wordCount words'),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Constants.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  /// Get current App version
  static Future<String> getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version.isNotEmpty &&
              packageInfo.buildNumber.isNotEmpty
          ? '${packageInfo.version} (Build ${packageInfo.buildNumber})'
          : '1.0.0 (Build 1)';
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
      return '1.0.0';
    }
  }
}
