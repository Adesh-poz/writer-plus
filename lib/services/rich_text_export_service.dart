import 'package:flutter_quill/quill_delta.dart';

class RichTextExportService {
  static String deltaToRtf(Delta delta) {
    final buffer = StringBuffer()
      ..write(r'{\rtf1\ansi\deff0')
      ..write(r'{\fonttbl{\f0 Arial;}}');

    for (final operation in delta.operations) {
      if (!operation.isInsert || operation.data is! String) continue;

      final attributes = operation.attributes ?? const <String, dynamic>{};
      final bold = attributes['bold'] == true;
      final italic = attributes['italic'] == true;
      final underline = attributes['underline'] == true;
      final strike = attributes['strike'] == true;

      if (bold) buffer.write(r'\b ');
      if (italic) buffer.write(r'\i ');
      if (underline) buffer.write(r'\ul ');
      if (strike) buffer.write(r'\strike ');

      for (final character in (operation.data as String).split('')) {
        if (character != '\n') {
          buffer.write(_escapeRtf(character));
          continue;
        }

        final lineHeight = _number(attributes['line-height']);
        if (lineHeight != null && lineHeight > 0) {
          buffer
            ..write(r'\sl')
            ..write((lineHeight * 240).round())
            ..write(r'\slmult1 ');
        } else {
          buffer.write(r'\sl0\slmult1 ');
        }
        buffer.write(r'\par ');
      }

      if (strike) buffer.write(r'\strike0 ');
      if (underline) buffer.write(r'\ul0 ');
      if (italic) buffer.write(r'\i0 ');
      if (bold) buffer.write(r'\b0 ');
    }

    buffer.write('}');
    return buffer.toString();
  }

  static Delta rtfToDelta(String rtf) {
    final delta = Delta();
    final states = <_State>[_State()];
    final text = StringBuffer();
    Map<String, dynamic>? textAttributes;

    void flushText() {
      if (text.isEmpty) return;
      delta.insert(text.toString(), textAttributes);
      text.clear();
      textAttributes = null;
    }

    void append(String value, _State state) {
      if (state.skip) return;
      final attributes = Map<String, dynamic>.of(state.inline);
      if (text.isNotEmpty && !_same(textAttributes, attributes)) flushText();
      textAttributes ??= attributes.isEmpty ? null : attributes;
      text.write(value);
    }

    var index = 0;
    while (index < rtf.length) {
      final character = rtf[index];
      final state = states.last;

      if (character == '{') {
        flushText();
        states.add(state.copy());
        index++;
        continue;
      }
      if (character == '}') {
        flushText();
        if (states.length > 1) states.removeLast();
        index++;
        continue;
      }
      if (character == '\r' || character == '\n') {
        index++;
        continue;
      }
      if (character != r'\') {
        append(character, state);
        index++;
        continue;
      }

      index++;
      if (index >= rtf.length) break;
      final next = rtf[index];
      if (next == r'\' || next == '{' || next == '}') {
        append(next, state);
        index++;
        continue;
      }
      if (!RegExp(r'[A-Za-z]').hasMatch(next)) {
        if (next == '*') state.skip = true;
        if (next == '~') append('\u00a0', state);
        index++;
        continue;
      }

      final wordStart = index;
      while (index < rtf.length && RegExp(r'[A-Za-z]').hasMatch(rtf[index])) {
        index++;
      }
      final word = rtf.substring(wordStart, index).toLowerCase();
      final numberStart = index;
      if (index < rtf.length && rtf[index] == '-') index++;
      while (index < rtf.length && RegExp(r'\d').hasMatch(rtf[index])) {
        index++;
      }
      final number =
          index == numberStart ||
              (index == numberStart + 1 && rtf[numberStart] == '-')
          ? null
          : int.tryParse(rtf.substring(numberStart, index));
      if (index < rtf.length && rtf[index] == ' ') index++;

      switch (word) {
        case 'fonttbl':
        case 'colortbl':
        case 'stylesheet':
        case 'info':
        case 'pict':
        case 'object':
          state.skip = true;
        case 'par':
        case 'line':
          flushText();
          final multiplier = state.spacingMultiplier;
          final twips = state.spacingTwips;
          final lineHeight = multiplier == 1 && twips != null && twips > 0
              ? twips / 240
              : null;
          delta.insert(
            '\n',
            lineHeight == null ? null : {'line-height': lineHeight},
          );
        case 'tab':
          append('\t', state);
        case 'b':
          _setAttribute(state, 'bold', number != 0);
        case 'i':
          _setAttribute(state, 'italic', number != 0);
        case 'ul':
          _setAttribute(state, 'underline', number != 0);
        case 'ulnone':
          _setAttribute(state, 'underline', false);
        case 'strike':
          _setAttribute(state, 'strike', number != 0);
        case 'sl':
          state.spacingTwips = number;
        case 'slmult':
          state.spacingMultiplier = number;
      }
    }

    flushText();
    return delta;
  }

  static String _escapeRtf(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('{', r'\{')
      .replaceAll('}', r'\}')
      .replaceAll('\t', r'\tab ');

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse(value.toString());
  }

  static void _setAttribute(_State state, String key, bool enabled) {
    if (enabled) {
      state.inline[key] = true;
    } else {
      state.inline.remove(key);
    }
  }

  static bool _same(Map<String, dynamic>? first, Map<String, dynamic> second) {
    if (first == null) return second.isEmpty;
    if (first.length != second.length) return false;
    return first.entries.every((entry) => second[entry.key] == entry.value);
  }
}

class _State {
  _State({
    this.skip = false,
    Map<String, dynamic>? inline,
    this.spacingTwips,
    this.spacingMultiplier,
  }) : inline = inline ?? {};

  bool skip;
  final Map<String, dynamic> inline;
  int? spacingTwips;
  int? spacingMultiplier;

  _State copy() => _State(
    skip: skip,
    inline: Map.of(inline),
    spacingTwips: spacingTwips,
    spacingMultiplier: spacingMultiplier,
  );
}
