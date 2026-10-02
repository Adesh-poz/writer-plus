import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/helpers/helpers.dart';
import 'package:writer_plus/reusables/writer_plus_logo_text.dart';
import 'package:writer_plus/reusables/writer_snack_bar.dart';
import 'package:writer_plus/screens/folder_page.dart';
import 'package:writer_plus/screens/text_editor.dart';
import 'package:writer_plus/services/file_service.dart';

class WriterPlusHomePage extends StatefulWidget {
  const WriterPlusHomePage({super.key});

  @override
  State<WriterPlusHomePage> createState() => _WriterPlusHomePageState();
}

class _WriterPlusHomePageState extends State<WriterPlusHomePage> {
  Directory? _rootDirectory;
  List<AppFileSystemItem> _items = [];
  bool _isLoading = true;

  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _initIntentListener();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _initIntentListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            _handleIncomingFiles(value);
          },
          onError: (err) {
            if (kDebugMode) debugPrint("getMediaStream error: $err");
          },
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      _handleIncomingFiles(value);
    });
  }

  Future<void> _handleIncomingFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    ReceiveSharingIntent.instance.reset();

    for (final sharedFile in files) {
      if (sharedFile.path.isNotEmpty) {
        try {
          final externalFile = File(sharedFile.path);
          if (await externalFile.exists()) {
            final rootDir = await FileService().getRootDirectory();
            final fileName = externalFile.path
                .split(Platform.pathSeparator)
                .last;
            final content = await externalFile.readAsString();

            String ext = 'txt';
            final dot = fileName.lastIndexOf('.');
            if (dot != -1) {
              ext = fileName.substring(dot + 1).toLowerCase();
            }

            final savedFile = await FileService().saveFile(
              parentDirectory: rootDir,
              fileName: fileName,
              content: content,
              extension: ext,
              allowOverwrite: false,
            );

            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TextEditor(
                  filePath: savedFile.path,
                  initialTitle: savedFile.path
                      .split(Platform.pathSeparator)
                      .last,
                ),
              ),
            );
            _loadItems();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error handling incoming file: $e');
        }
      }
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rootDir = await FileService().getRootDirectory();
      final items = await FileService().getDirectoryItems(rootDir);

      if (mounted) {
        setState(() {
          _rootDirectory = rootDir;
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WriterSnackBar.show(
          context,
          'Failed to load storage: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _createNewFile() async {
    if (_rootDirectory == null) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TextEditor(parentDirectoryPath: _rootDirectory!.path),
      ),
    );

    _loadItems();
  }

  String _displayName(String name) {
    final lastDot = name.lastIndexOf('.');
    if (lastDot > 0) {
      final ext = name.substring(lastDot + 1).toLowerCase();
      if (ext == 'txt' ||
          ext == 'md' ||
          ext == 'rtf' ||
          ext == 'doc' ||
          ext == 'docx') {
        return name.substring(0, lastDot);
      }
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const WriterPlusLogoText(),
        actions: [
          IconButton(
            tooltip: 'New Folder',
            onPressed: () {
              if (_rootDirectory != null) {
                Helper.showCreateFolderDialog(
                  context,
                  _rootDirectory!,
                  _loadItems,
                );
              }
            },
            icon: const FaIcon(FontAwesomeIcons.folderPlus),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Constants.primaryColor),
            )
          : _items.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadItems,
              color: Constants.primaryColor,
              child: ListView.separated(
                itemCount: _items.length,
                padding: const EdgeInsets.only(bottom: 80),
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 50,
                  color: Colors.grey.shade900,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return ListTile(
                    onTap: () async {
                      if (item.isDirectory) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderPage(
                              folderId: item.path,
                              folderName: item.name,
                            ),
                          ),
                        );
                        _loadItems();
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TextEditor(
                              filePath: item.path,
                              initialTitle: item.name,
                            ),
                          ),
                        );
                        _loadItems();
                      }
                    },
                    visualDensity: VisualDensity.comfortable,
                    contentPadding: const EdgeInsets.fromLTRB(12, 0, 5, 0),
                    leading: FaIcon(
                      item.isDirectory
                          ? FontAwesomeIcons.solidFolder
                          : FontAwesomeIcons.solidFileLines,
                      color: Constants.primaryColor,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.isDirectory
                                ? item.name
                                : _displayName(item.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Constants.headingTS,
                          ),
                        ),
                        if (!item.isDirectory && item.extension.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Helper.getFileTypeColor(
                                item.extension,
                              ).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 6,
                            ),
                            child: Text(
                              '.${item.extension}',
                              style: Constants.headingTS.copyWith(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      'Last Modified ${item.formattedLastModified}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Constants.bodyTS,
                    ),
                    trailing: PopupMenuButton<int>(
                      tooltip: 'Show Actions',
                      borderRadius: BorderRadius.circular(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      onSelected: (action) async {
                        switch (action) {
                          case 1: // Move to
                            if (_rootDirectory != null) {
                              await Helper.showMoveToDialog(
                                context,
                                item,
                                _rootDirectory!,
                                _loadItems,
                              );
                            }
                            break;
                          case 2: // Rename
                            await Helper.showRenameDialog(
                              context,
                              item,
                              _loadItems,
                            );
                            break;
                          case 3: // Delete
                            await Helper.showDeleteDialog(
                              context,
                              item,
                              _loadItems,
                            );
                            break;
                          case 4: // Share
                            await Helper.handleShare(context, item);
                            break;
                          case 5: // Details
                            await Helper.showDetailsDialog(context, item);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem(value: 1, child: Text('Move to')),
                          const PopupMenuItem(value: 2, child: Text('Rename')),
                          const PopupMenuItem(
                            value: 3,
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          if (!item.isDirectory)
                            const PopupMenuItem(value: 4, child: Text('Share')),
                          const PopupMenuItem(value: 5, child: Text('Details')),
                        ];
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFile,
        tooltip: 'New File',
        backgroundColor: Constants.primaryColor,
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            size: 64,
            color: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),
          Text(
            'No files or folders yet',
            style: Constants.headingTS.copyWith(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a file or folder icon to add a folder.',
            style: Constants.bodyTS.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
