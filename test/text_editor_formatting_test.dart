import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

import 'package:writer_plus/services/markdown_export_service.dart';
import 'package:writer_plus/services/rich_text_export_service.dart';

void main() {
  test(
    'saved inline defaults are applied to text typed after caret changes',
    () {
      final controller = QuillController.basic();
      addTearDown(controller.dispose);

      controller.onSelectionChanged = (selection) {
        if (!selection.isCollapsed) return;

        controller.toggledStyle = controller.toggledStyle
            .put(Attribute.fromKeyValue('font', 'serif')!)
            .put(Attribute.fromKeyValue('size', '18')!);
      };

      controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      controller.replaceText(
        0,
        0,
        'H',
        const TextSelection.collapsed(offset: 1),
      );

      final typedText = controller.document.toDelta().operations.first;
      expect(typedText.data, 'H');
      expect(typedText.attributes, containsPair('font', 'serif'));
      expect(double.parse(typedText.attributes!['size'].toString()), 18);
    },
  );

  test(
    'saved inline defaults cover loaded text and caret moves to the end',
    () {
      final controller = QuillController.basic();
      addTearDown(controller.dispose);
      controller.document = Document()..insert(0, 'Saved text');

      final contentLength = controller.document.length - 1;
      controller.formatText(
        0,
        contentLength,
        Attribute.fromKeyValue('font', 'serif'),
      );
      controller.formatText(
        0,
        contentLength,
        Attribute.fromKeyValue('size', '18'),
      );
      controller.moveCursorToEnd();

      final savedText = controller.document.toDelta().operations.first;
      expect(savedText.data, 'Saved text');
      expect(savedText.attributes, containsPair('font', 'serif'));
      expect(double.parse(savedText.attributes!['size'].toString()), 18);
      expect(controller.selection.extentOffset, contentLength);
    },
  );

  test('Markdown punctuation escapes are decoded and remain stable', () {
    final markdownDocument = md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final markdownToDelta = MarkdownToDelta(markdownDocument: markdownDocument);
    const source = r'Hi there, hello\!';

    final firstDelta = markdownToDelta.convert(source);
    final plainText = Document.fromDelta(firstDelta).toPlainText().trim();
    final secondSource = DeltaToMarkdown().convert(firstDelta);
    final secondDelta = markdownToDelta.convert(secondSource);
    final secondPlainText = Document.fromDelta(
      secondDelta,
    ).toPlainText().trim();

    expect(plainText, 'Hi there, hello!');
    expect(secondPlainText, plainText);
  });

  test('RTF preserves line height and repeated blank paragraphs', () {
    final source = Delta()
      ..insert('First paragraph')
      ..insert('\n', {'line-height': 1.5})
      ..insert('\n', {'line-height': 1.5})
      ..insert('Second paragraph', {'bold': true})
      ..insert('\n', {'line-height': 2.0});

    final rtf = RichTextExportService.deltaToRtf(source);
    final restored = RichTextExportService.rtfToDelta(rtf);

    expect(restored.toJson(), source.toJson());
    expect(
      Document.fromDelta(restored).toPlainText(),
      'First paragraph\n\nSecond paragraph\n',
    );
  });

  test('Markdown preserves consecutive empty paragraphs in this editor', () {
    final source = Delta()
      ..insert('First')
      ..insert('\n', {'line-height': 1.5})
      ..insert('\n', {'line-height': 1.5})
      ..insert('\n', {'line-height': 2.0})
      ..insert('Second')
      ..insert('\n', {'line-height': 1.15});
    final markdown = MarkdownExportService.encode(source);
    final restored = MarkdownExportService.decode(markdown);

    expect(restored, isNotNull);
    expect(
      MarkdownExportService.stripMetadata(markdown),
      isNot(contains('writer-plus-delta')),
    );
    expect(Document.fromDelta(restored!).toPlainText(), 'First\n\n\nSecond\n');
    expect(restored.toJson(), source.toJson());
    expect(
      MarkdownExportService.decode(markdown.replaceFirst('First', 'Changed')),
      isNull,
    );
  });
}
