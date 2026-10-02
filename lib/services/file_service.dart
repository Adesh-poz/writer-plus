import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class AppFileSystemItem {
  final String name;
  final String path;
  final bool isDirectory;
  final DateTime lastModified;
  final int sizeInBytes;
  final String extension;
  final FileSystemEntity entity;

  AppFileSystemItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.lastModified,
    required this.sizeInBytes,
    required this.extension,
    required this.entity,
  });

  String get formattedLastModified {
    return DateFormat('dd MMM, yyyy h:mm a').format(lastModified);
  }

  String get formattedSize {
    if (isDirectory) return '';
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class StorageSummary {
  final int totalFiles;
  final int totalFolders;
  final int totalSizeBytes;
  final String rootPath;

  StorageSummary({
    required this.totalFiles,
    required this.totalFolders,
    required this.totalSizeBytes,
    required this.rootPath,
  });

  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Directory? _rootDirectory;

  /// Returns the root directory for in-app storage ('WriterPlus' in shared root storage on Android, local space on iOS).
  Future<Directory> getRootDirectory() async {
    if (_rootDirectory != null && await _rootDirectory!.exists()) {
      return _rootDirectory!;
    }

    Directory rootDir;

    if (Platform.isAndroid) {
      try {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }
      } catch (_) {}

      try {
        final publicRoot = Directory('/storage/emulated/0');
        if (await publicRoot.exists()) {
          rootDir = Directory('${publicRoot.path}/WriterPlus');
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          rootDir = Directory('${appDocDir.path}/WriterPlus');
        }
      } catch (_) {
        final appDocDir = await getApplicationDocumentsDirectory();
        rootDir = Directory('${appDocDir.path}/WriterPlus');
      }
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      rootDir = Directory('${appDocDir.path}/WriterPlus');
    }

    if (!await rootDir.exists()) {
      try {
        await rootDir.create(recursive: true);
      } catch (e) {
        final appDocDir = await getApplicationDocumentsDirectory();
        rootDir = Directory('${appDocDir.path}/WriterPlus');
        if (!await rootDir.exists()) {
          await rootDir.create(recursive: true);
        }
      }
    }

    _rootDirectory = rootDir;
    return rootDir;
  }

  /// Lists all items (folders and files) in the specified directory.
  Future<List<AppFileSystemItem>> getDirectoryItems(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<AppFileSystemItem> items = [];

    for (final entity in entities) {
      final name = entity.path.split(Platform.pathSeparator).last;

      // Skip hidden files or system entries if any
      if (name.startsWith('.')) continue;

      final stat = await entity.stat();
      final isDir = entity is Directory;

      String ext = '';
      if (!isDir) {
        final dotIndex = name.lastIndexOf('.');
        if (dotIndex != -1 && dotIndex < name.length - 1) {
          ext = name.substring(dotIndex + 1).toLowerCase();
        }
      }

      items.add(
        AppFileSystemItem(
          name: name,
          path: entity.path,
          isDirectory: isDir,
          lastModified: stat.modified,
          sizeInBytes: isDir ? 0 : stat.size,
          extension: ext,
          entity: entity,
        ),
      );
    }

    // Sort: Folders first (A-Z), then Files (A-Z)
    items.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  /// Creates a new folder inside the parent directory.
  Future<Directory> createFolder(
    Directory parentDirectory,
    String folderName,
  ) async {
    final sanitizedName = folderName.trim();
    if (sanitizedName.isEmpty) {
      throw Exception('Folder name cannot be empty');
    }

    final newFolderPath =
        '${parentDirectory.path}${Platform.pathSeparator}$sanitizedName';
    final newDir = Directory(newFolderPath);

    if (await newDir.exists()) {
      throw Exception('Folder "$sanitizedName" already exists.');
    }

    return await newDir.create(recursive: true);
  }

  /// Saves or creates a document file inside the parent directory.
  Future<File> saveFile({
    required Directory parentDirectory,
    required String fileName,
    required String content,
    String extension = 'txt',
    bool allowOverwrite = false,
  }) async {
    var cleanName = fileName.trim();
    if (cleanName.isEmpty) {
      cleanName = 'New Document';
    }

    final extClean = extension.replaceAll('.', '').toLowerCase();

    // Strip any existing known document extension to prevent duplicate extensions like file.txt.md
    final lastDot = cleanName.lastIndexOf('.');
    if (lastDot != -1 && lastDot > 0) {
      final existingExt = cleanName.substring(lastDot + 1).toLowerCase();
      if (existingExt == 'txt' ||
          existingExt == 'md' ||
          existingExt == 'rtf' ||
          existingExt == 'doc' ||
          existingExt == 'docx') {
        cleanName = cleanName.substring(0, lastDot);
      }
    }

    final baseName = cleanName;
    var filePath =
        '${parentDirectory.path}${Platform.pathSeparator}$baseName.$extClean';

    if (!allowOverwrite) {
      int counter = 1;
      while (await File(filePath).exists()) {
        filePath =
            '${parentDirectory.path}${Platform.pathSeparator}$baseName ($counter).$extClean';
        counter++;
      }
    }

    final file = File(filePath);
    return await file.writeAsString(content);
  }

  /// Reads plain text content from a file.
  Future<String> readFile(File file) async {
    if (!await file.exists()) {
      return '';
    }
    return await file.readAsString();
  }

  /// Renames a file or directory.
  Future<FileSystemEntity> renameEntity(
    FileSystemEntity entity,
    String newName,
  ) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    final parentPath = entity.parent.path;
    String finalNewName = trimmedName;

    // For files, preserve original extension if user didn't specify one
    if (entity is File) {
      final oldName = entity.path.split(Platform.pathSeparator).last;
      final oldDotIndex = oldName.lastIndexOf('.');
      if (oldDotIndex != -1) {
        final oldExt = oldName.substring(oldDotIndex);
        if (!finalNewName.toLowerCase().contains('.')) {
          finalNewName = '$finalNewName$oldExt';
        }
      }
    }

    final newPath = '$parentPath${Platform.pathSeparator}$finalNewName';
    if (newPath == entity.path) {
      return entity;
    }

    if (await FileSystemEntity.type(newPath) != FileSystemEntityType.notFound) {
      throw Exception('An item with the name "$finalNewName" already exists.');
    }

    return await entity.rename(newPath);
  }

  /// Deletes a file or folder.
  Future<void> deleteEntity(FileSystemEntity entity) async {
    if (await entity.exists()) {
      await entity.delete(recursive: true);
    }
  }

  /// Moves a file or folder to a destination directory.
  Future<FileSystemEntity> moveEntity(
    FileSystemEntity entity,
    Directory destinationDirectory,
  ) async {
    if (!await destinationDirectory.exists()) {
      await destinationDirectory.create(recursive: true);
    }

    final name = entity.path.split(Platform.pathSeparator).last;
    final targetPath =
        '${destinationDirectory.path}${Platform.pathSeparator}$name';

    if (targetPath == entity.path) {
      return entity;
    }

    if (await FileSystemEntity.type(targetPath) !=
        FileSystemEntityType.notFound) {
      throw Exception('An item named "$name" already exists in destination.');
    }

    return await entity.rename(targetPath);
  }

  /// Recursively lists all subdirectories under root for "Move to" location selection.
  Future<List<Directory>> getAllFolders(Directory rootDir) async {
    final List<Directory> folders = [rootDir];

    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Directory) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (!name.startsWith('.')) {
          folders.add(entity);
        }
      }
    }

    return folders;
  }

  /// Shares a file out-of-app using share_plus.
  Future<void> shareFile(File file) async {
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Sharing from Writer Plus'),
    );
  }

  /// Computes word count from text content.
  int calculateWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Computes overall storage summary (total files, subfolders, disk space used, root path).
  Future<StorageSummary> getStorageSummary() async {
    final rootDir = await getRootDirectory();
    int fileCount = 0;
    int folderCount = 0;
    int totalBytes = 0;

    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        folderCount++;
      } else if (entity is File) {
        fileCount++;
        final stat = await entity.stat();
        totalBytes += stat.size;
      }
    }

    return StorageSummary(
      totalFiles: fileCount,
      totalFolders: folderCount,
      totalSizeBytes: totalBytes,
      rootPath: rootDir.path,
    );
  }
}
