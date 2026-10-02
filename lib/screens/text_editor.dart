import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/reusables/writer_snack_bar.dart';
import 'package:writer_plus/services/file_service.dart';
import 'package:writer_plus/services/markdown_export_service.dart';
import 'package:writer_plus/services/preferences_service.dart';
import 'package:writer_plus/services/rich_text_export_service.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({
    super.key,
    this.filePath,
    this.initialTitle,
    this.parentDirectoryPath,
  });

  final String? filePath;
  final String? initialTitle;
  final String? parentDirectoryPath;

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  DateTime _updatedAt = DateTime.now();
  bool _hasChanges = false;

  late String _documentTitle;
  String? _currentFilePath;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _defaultFontFamily;
  String? _defaultFontSize;

  @override
  void initState() {
    super.initState();

    _controller = QuillController.basic();
    _controller.onSelectionChanged = _applySavedTypingStyle;
    _currentFilePath = widget.filePath;

    // Set document title
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _documentTitle = _removeExtension(widget.initialTitle!);
    } else if (widget.filePath != null) {
      final name = widget.filePath!.split(Platform.pathSeparator).last;
      _documentTitle = _removeExtension(name);
    } else {
      _documentTitle = 'New Document';
    }

    _controller.addListener(_onDocumentChanged);
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    try {
      await _loadExistingFileContent();
      await _loadPreferences();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasChanges = false;
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    final savedFamily = await PreferencesService.getFontFamily();
    final savedSize = await PreferencesService.getFontSize();

    if (!mounted) return;

    _defaultFontFamily = savedFamily;
    _defaultFontSize = savedSize;

    final contentLength = _controller.document.length - 1;
    if (contentLength > 0) {
      final familyAttribute = savedFamily == null || savedFamily.isEmpty
          ? null
          : Attribute.fromKeyValue('font', savedFamily);
      if (familyAttribute != null) {
        _controller.formatText(0, contentLength, familyAttribute);
      }

      final sizeAttribute = savedSize == null || savedSize.isEmpty
          ? null
          : Attribute.fromKeyValue('size', savedSize);
      if (sizeAttribute != null) {
        _controller.formatText(0, contentLength, sizeAttribute);
      }
    }

    _controller.moveCursorToEnd();
  }

  void _applySavedTypingStyle(TextSelection selection) {
    if (!selection.isCollapsed) return;

    final fontFamily = _defaultFontFamily;
    if (fontFamily != null && fontFamily.isNotEmpty) {
      final attribute = Attribute.fromKeyValue('font', fontFamily);
      if (attribute != null) {
        _controller.toggledStyle = _controller.toggledStyle.put(attribute);
      }
    }

    final fontSize = _defaultFontSize;
    if (fontSize != null && fontSize.isNotEmpty) {
      final attribute = Attribute.fromKeyValue('size', fontSize);
      if (attribute != null) {
        _controller.toggledStyle = _controller.toggledStyle.put(attribute);
      }
    }
  }

  String _removeExtension(String fileName) {
    var name = fileName;
    while (true) {
      final lastDot = name.lastIndexOf('.');
      if (lastDot > 0) {
        final ext = name.substring(lastDot + 1).toLowerCase();
        if (ext == 'txt' ||
            ext == 'md' ||
            ext == 'rtf' ||
            ext == 'doc' ||
            ext == 'docx') {
          name = name.substring(0, lastDot);
          continue;
        }
      }
      break;
    }
    return name;
  }

  Future<void> _loadExistingFileContent() async {
    if (_currentFilePath == null) return;

    final file = File(_currentFilePath!);
    if (!await file.exists()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rawText = await FileService().readFile(file);
      final stat = await file.stat();

      final ext = _currentFilePath!.split('.').last.toLowerCase();

      if (ext == 'rtf' || rawText.startsWith(r'{\rtf')) {
        _controller.document = Document.fromDelta(
          RichTextExportService.rtfToDelta(rawText),
        );
      } else if (rawText.isNotEmpty && ext == 'md') {
        final savedDelta = MarkdownExportService.decode(rawText);
        if (savedDelta != null) {
          _controller.document = Document.fromDelta(savedDelta);
        } else {
          final markdownToDelta = MarkdownToDelta(
            markdownDocument: md.Document(
              encodeHtml: false,
              extensionSet: md.ExtensionSet.gitHubFlavored,
            ),
          );
          _controller.document = Document.fromDelta(
            markdownToDelta.convert(
              MarkdownExportService.stripMetadata(rawText),
            ),
          );
        }
      } else if (rawText.isNotEmpty) {
        _controller.document = Document()..insert(0, rawText);
      }

      _updatedAt = stat.modified;
    } catch (e) {
      if (mounted) {
        WriterSnackBar.show(
          context,
          'Error loading document: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDocumentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
        _updatedAt = DateTime.now();
      });
    } else {
      setState(() {
        _updatedAt = DateTime.now();
      });
    }
  }

  int get _wordCount {
    final text = _controller.document.toPlainText().trim();
    if (text.isEmpty) {
      return 0;
    }
    return text.split(RegExp(r'\s+')).length;
  }

  void _showStatisticsDialog() {
    final text = _controller.document.toPlainText();
    final cleanText = text.endsWith('\n')
        ? text.substring(0, text.length - 1)
        : text;

    final trimmed = cleanText.trim();
    final words = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    final charsWithSpaces = cleanText.length;
    final charsWithoutSpaces = cleanText.replaceAll(RegExp(r'\s'), '').length;

    // Average reading speed: 200 WPM
    final totalSeconds = words == 0 ? 0 : (words / 200 * 60).ceil();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final humanReadable = '$hours hours $minutes mins $seconds seconds';
    final timerFormat =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: const [
              FaIcon(
                FontAwesomeIcons.chartSimple,
                color: Constants.primaryColor,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Document Statistics',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Word Count', '$words words'),
              const SizedBox(height: 10),
              _statRow('Character Count (with spaces)', '$charsWithSpaces'),
              const SizedBox(height: 10),
              _statRow(
                'Character Count (without spaces)',
                '$charsWithoutSpaces',
              ),
              const SizedBox(height: 10),
              _statRow('Estimated Reading Time (Human)', humanReadable),
              const SizedBox(height: 10),
              _statRow('Estimated Reading Time (Timer)', timerFormat),
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

  Widget _statRow(String label, String value) {
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Future<void> _showRenameDialog() async {
    final textController = TextEditingController(text: _documentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Rename Document',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter document name',
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

    if (newTitle != null && newTitle.isNotEmpty && newTitle != _documentTitle) {
      final cleanNewTitle = _removeExtension(newTitle);

      setState(() {
        _documentTitle = cleanNewTitle;
        _hasChanges = true;
      });

      // If file already saved on disk, rename it on disk as well
      if (_currentFilePath != null) {
        final currentFile = File(_currentFilePath!);
        if (await currentFile.exists()) {
          try {
            final renamedEntity = await FileService().renameEntity(
              currentFile,
              cleanNewTitle,
            );
            setState(() {
              _currentFilePath = renamedEntity.path;
            });
          } catch (e) {
            if (mounted) {
              WriterSnackBar.show(
                context,
                'Failed to rename file on disk: $e',
                isError: true,
              );
            }
          }
        }
      }
    }
  }

  // Save / Exit Handler
  Future<void> _handleBack() async {
    final plainText = _controller.document.toPlainText().trim();

    if (!_hasChanges || plainText.isEmpty) {
      if (mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Save Document?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This document has unsaved changes.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == 'discard') {
      if (mounted) {
        Navigator.pop(context, false);
      }
      return;
    }

    if (result == 'save') {
      final saved = await _saveSmart();
      if (saved && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  // Smart Save: Quick-saves existing file, or prompts format picker for new file
  Future<bool> _saveSmart() async {
    if (_currentFilePath != null) {
      final ext = _currentFilePath!.split('.').last.toLowerCase();
      SaveFormat format = SaveFormat.txt;
      if (ext == 'md') {
        format = SaveFormat.md;
      } else if (ext == 'rtf') {
        format = SaveFormat.rtf;
      }
      return await _saveToInAppDirectory(format);
    } else {
      return await _showSaveAsDialog();
    }
  }

  // Save As Dialog (For new documents)
  Future<bool> _showSaveAsDialog() async {
    final format = await showModalBottomSheet<SaveFormat>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select File Format',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              _saveFormatTile(
                context,
                icon: FontAwesomeIcons.fileLines,
                title: 'Text',
                subtitle: 'Plain text (.txt)',
                format: SaveFormat.txt,
              ),

              _saveFormatTile(
                context,
                icon: FontAwesomeIcons.fileWord,
                title: 'Rich Text',
                subtitle: 'Rich Text Format (.rtf)',
                format: SaveFormat.rtf,
              ),

              _saveFormatTile(
                context,
                icon: FontAwesomeIcons.markdown,
                title: 'Markdown',
                subtitle: 'Markdown (.md)',
                format: SaveFormat.md,
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (format == null) {
      return false;
    }

    return await _saveToInAppDirectory(format);
  }

  Widget _saveFormatTile(
    BuildContext context, {
    required FaIconData icon,
    required String title,
    required String subtitle,
    required SaveFormat format,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: Constants.primaryColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        Navigator.pop(context, format);
      },
    );
  }

  // Save Document to In-App Local Directory
  Future<bool> _saveToInAppDirectory(SaveFormat format) async {
    try {
      final export = _buildExport(format);

      Directory targetDirectory;
      if (widget.parentDirectoryPath != null) {
        targetDirectory = Directory(widget.parentDirectoryPath!);
      } else if (_currentFilePath != null) {
        targetDirectory = File(_currentFilePath!).parent;
      } else {
        targetDirectory = await FileService().getRootDirectory();
      }

      final savedFile = await FileService().saveFile(
        parentDirectory: targetDirectory,
        fileName: _documentTitle,
        content: export.content,
        extension: export.extension,
        allowOverwrite: _currentFilePath != null,
      );

      setState(() {
        _currentFilePath = savedFile.path;
        _documentTitle = _removeExtension(
          savedFile.path.split(Platform.pathSeparator).last,
        );
        _hasChanges = false;
      });

      if (mounted) {
        WriterSnackBar.show(
          context,
          'Document "$_documentTitle.${export.extension}" saved.',
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        WriterSnackBar.show(
          context,
          'Failed to save document: $e',
          isError: true,
        );
      }
      return false;
    }
  }

  // Export Conversion
  ExportResult _buildExport(SaveFormat format) {
    switch (format) {
      case SaveFormat.txt:
        return ExportResult(
          fileName: '$_documentTitle.txt',
          extension: 'txt',
          mimeType: 'text/plain',
          content: _controller.document.toPlainText(),
        );

      case SaveFormat.md:
        final markdown = MarkdownExportService.encode(
          _controller.document.toDelta(),
        );

        return ExportResult(
          fileName: '$_documentTitle.md',
          extension: 'md',
          mimeType: 'text/markdown',
          content: markdown,
        );

      case SaveFormat.rtf:
        return ExportResult(
          fileName: '$_documentTitle.rtf',
          extension: 'rtf',
          mimeType: 'application/rtf',
          content: RichTextExportService.deltaToRtf(
            _controller.document.toDelta(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(keyboardVisible ? 0 : kToolbarHeight),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: keyboardVisible ? 0 : 1,
            child: AppBar(
              backgroundColor: Colors.black,
              automaticallyImplyLeading: true,
              leading: IconButton(
                tooltip: 'Go Back',
                onPressed: _handleBack,
                icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 18),
              ),
              titleSpacing: 0.0,
              title: GestureDetector(
                onTap: _showRenameDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _documentTitle,
                        style: Constants.headingTS.copyWith(fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 14,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Document Statistics',
                  onPressed: _showStatisticsDialog,
                  icon: const FaIcon(
                    FontAwesomeIcons.chartSimple,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Save Document',
                  onPressed: () async {
                    await _saveSmart();
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.solidFloppyDisk,
                    size: 18,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: _isLoading || _isInitializing
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Constants.primaryColor,
                  ),
                )
              : Column(
                  children: [
                    // Document Information Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _showStatisticsDialog,
                            child: Text(
                              'Words $_wordCount',
                              style: Constants.headingTS.copyWith(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy h:mm a').format(_updatedAt),
                            style: Constants.headingTS.copyWith(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Colors.white12),

                    // Editor
                    Expanded(
                      child: QuillEditor.basic(
                        controller: _controller,
                        focusNode: _focusNode,
                        config: QuillEditorConfig(
                          padding: const EdgeInsets.all(12),
                          autoFocus: true,
                          scrollPhysics: const BouncingScrollPhysics(),
                          customStyles: const DefaultStyles(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Toolbar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        5,
                        0,
                        keyboardVisible ? 0 : 10,
                      ),
                      child: QuillSimpleToolbar(
                        controller: _controller,
                        config: QuillSimpleToolbarConfig(
                          showLineHeightButton: true,
                          multiRowsDisplay: false,
                          showFontFamily: true,
                          showFontSize: true,
                          showHeaderStyle: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showListCheck: false,
                          showCodeBlock: false,
                          showInlineCode: false,
                          showLink: false,
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            fontFamily: QuillToolbarFontFamilyButtonOptions(
                              onSelected: (family) async {
                                if (family == 'Clear') {
                                  _defaultFontFamily = null;
                                  await PreferencesService.clearFontFamily();
                                } else {
                                  _defaultFontFamily = family;
                                  await PreferencesService.saveFontFamily(
                                    family,
                                  );
                                }
                              },
                            ),
                            fontSize: QuillToolbarFontSizeButtonOptions(
                              onSelected: (size) async {
                                if (size == '0') {
                                  _defaultFontSize = null;
                                  await PreferencesService.clearFontSize();
                                } else {
                                  _defaultFontSize = size;
                                  await PreferencesService.saveFontSize(size);
                                }
                              },
                              items: {
                                'Normal Text': '12',
                                'Heading 1': '28',
                                'Heading 2': '22',
                                'Heading 3': '18',
                                '8': '8',
                                '9': '9',
                                '10': '10',
                                '11': '11',
                                '12': '12',
                                '14': '14',
                                '16': '16',
                                '18': '18',
                                '20': '20',
                                '24': '24',
                                '28': '28',
                                '36': '36',
                                '48': '48',
                                '72': '72',
                                'Clear': '0',
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Save format enum
enum SaveFormat { txt, rtf, md }

// Export result helper/data structure
class ExportResult {
  final String fileName;
  final String extension;
  final String mimeType;
  final String content;

  const ExportResult({
    required this.fileName,
    required this.extension,
    required this.mimeType,
    required this.content,
  });
}
