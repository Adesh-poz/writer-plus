import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/helpers/helpers.dart';
import 'package:writer_plus/reusables/back_button.dart';
import 'package:writer_plus/reusables/writer_snack_bar.dart';
import 'package:writer_plus/screens/text_editor.dart';
import 'package:writer_plus/services/file_service.dart';

class FolderPage extends StatefulWidget {
  const FolderPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final String folderId;
  final String folderName;

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  late Directory _currentFolder;
  Directory? _rootDirectory;
  List<AppFileSystemItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentFolder = Directory(widget.folderId);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rootDir = await FileService().getRootDirectory();
      final items = await FileService().getDirectoryItems(_currentFolder);

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
          'Failed to load folder contents: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _createNewFile() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TextEditor(parentDirectoryPath: _currentFolder.path),
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
        leading: const WriterBackButton(),
        titleSpacing: 0.0,
        title: Text(
          widget.folderName,
          style: Constants.headingTS.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'New Folder',
            onPressed: () {
              Helper.showCreateFolderDialog(
                context,
                _currentFolder,
                _loadItems,
              );
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
            'This folder is empty',
            style: Constants.headingTS.copyWith(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a file or folder icon to add a subfolder.',
            style: Constants.bodyTS.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
