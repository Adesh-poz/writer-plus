import 'dart:convert';

import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';

class MarkdownExportService {
  static final _metadataPattern = RegExp(
    r'<!--writer-plus-delta:v1:([0-9a-f]{8}):([01]):([A-Za-z0-9_-]+)-->',
  );

  static String encode(Delta delta) {
    final markdown = DeltaToMarkdown().convert(delta);
    if (!_needsDeltaMetadata(delta)) return markdown;

    final addSeparator = !markdown.endsWith('\n');
    final body = addSeparator ? '$markdown\n' : markdown;
    final checksum = _checksum(markdown).toRadixString(16).padLeft(8, '0');
    final deltaJson = jsonEncode(delta.toJson());
    final payload = base64Url
        .encode(utf8.encode(deltaJson))
        .replaceAll('=', '');
    final separatorFlag = addSeparator ? '1' : '0';

    return '$body<!--writer-plus-delta:v1:$checksum:$separatorFlag:$payload-->';
  }

  static Delta? decode(String markdown) {
    final match = _metadataPattern.firstMatch(markdown);
    if (match == null) return null;

    final metadataStart = match.start;
    var body = markdown.substring(0, metadataStart);
    if (match.group(2) == '1' && body.endsWith('\n')) {
      body = body.substring(0, body.length - 1);
    }
    if (_checksum(body).toRadixString(16).padLeft(8, '0') != match.group(1)) {
      return null;
    }

    try {
      final encoded = base64Url.normalize(match.group(3)!);
      final decoded = utf8.decode(base64Url.decode(encoded));
      final json = jsonDecode(decoded) as List<dynamic>;
      return Delta.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static String stripMetadata(String markdown) {
    return markdown.replaceFirst(_metadataPattern, '');
  }

  static bool _needsDeltaMetadata(Delta delta) {
    var consecutiveNewlines = 0;
    for (final operation in delta.operations) {
      if (!operation.isInsert || operation.data is! String) continue;

      final attributes = operation.attributes ?? const <String, dynamic>{};
      if (attributes['line-height'] != null) return true;

      for (final character in (operation.data as String).split('')) {
        if (character == '\n') {
          consecutiveNewlines++;
          if (consecutiveNewlines > 1) return true;
        } else {
          consecutiveNewlines = 0;
        }
      }
    }
    return false;
  }

  static int _checksum(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
