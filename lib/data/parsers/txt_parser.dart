import 'dart:io';

import '../../domain/entities/content_block.dart';
import '../../domain/result.dart';
import '../../core/errors/failures.dart';
import 'difficulty_heuristic.dart';
import 'parser_registry.dart';

/// Parser for plain text files (.txt).
///
/// Splits on blank lines into paragraphs. Detects headings via heuristics:
/// short lines (< 80 chars), no terminal punctuation, title-case-ish, or
/// Markdown `#` prefixes.
class TxtParser implements DocumentParser {
  @override
  List<String> get supportedExtensions => ['txt', 'text'];

  @override
  Future<Result<ParseOutput>> parse(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return parseContent(content, filePath);
    } catch (e) {
      return const Result.failure(ParseFailure());
    }
  }

  /// Parse content directly — used by tests and the web path where file bytes
  /// are already in memory.
  Result<ParseOutput> parseContent(String content, String filePath) {
    if (content.trim().isEmpty) return const Result.failure(ParseFailure());

    final blocks = _parseContent(content);
    if (blocks.isEmpty) return const Result.failure(ParseFailure());

    final wordCount = blocks.fold(0, (sum, b) => sum + b.wordCount);
    final title = _extractTitle(content) ?? _extractTitleFromPath(filePath);

    return Result.success(ParseOutput(
      blocks: blocks,
      title: title,
      wordCount: wordCount,
      parseConfidence: 1.0,
    ));
  }

  List<ContentBlock> _parseContent(String content) {
    final blocks = <ContentBlock>[];
    final paragraphs = content.split(RegExp(r'\n\s*\n'));

    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;

      if (_isHeading(trimmed)) {
        blocks.add(HeadingBlock(text: trimmed, level: _headingLevel(trimmed)));
      } else if (_isList(trimmed)) {
        blocks.add(ListBlock(items: _parseListItems(trimmed), ordered: _isOrderedList(trimmed)));
      } else {
        blocks.add(ParagraphBlock(
          text: trimmed,
          difficulty: estimateDifficulty(trimmed),
        ));
      }
    }

    return blocks;
  }

  bool _isHeading(String line) {
    if (line.isEmpty || line.length > 80) return false;
    if (line.startsWith('#')) return true;
    if (line == line.toUpperCase() && line.length < 60 && RegExp(r'[A-Z]').hasMatch(line)) return true;
    if (line.length < 60 && !RegExp(r'[.!?,;:]$').hasMatch(line)) {
      final wc = RegExp(r'\S+').allMatches(line).length;
      return wc > 0 && wc <= 8;
    }
    return false;
  }

  int _headingLevel(String line) {
    if (line.startsWith('######')) return 6;
    if (line.startsWith('#####')) return 5;
    if (line.startsWith('####')) return 4;
    if (line.startsWith('###')) return 3;
    if (line.startsWith('##')) return 2;
    if (line.startsWith('#')) return 1;
    return 2;
  }

  bool _isList(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    if (lines.isEmpty) return false;
    final bulletCount = lines.where((l) =>
      RegExp(r'^[-*•]\s').hasMatch(l.trim()) ||
      RegExp(r'^\d+[.)]\s').hasMatch(l.trim())
    ).length;
    return bulletCount >= lines.length * 0.5;
  }

  bool _isOrderedList(String text) =>
    RegExp(r'^\d+[.)]\s', multiLine: true).hasMatch(text);

  List<ListItem> _parseListItems(String text) {
    final items = <ListItem>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cleaned = trimmed
        .replaceFirst(RegExp(r'^[-*•]\s'), '')
        .replaceFirst(RegExp(r'^\d+[.)]\s'), '');
      final indent = line.length - line.trimLeft().length;
      items.add(ListItem(text: cleaned.trim(), level: indent ~/ 2));
    }
    return items;
  }

  String? _extractTitle(String content) {
    final firstLine = content.split('\n').firstOrNull;
    if (firstLine != null && firstLine.trim().isNotEmpty && _isHeading(firstLine.trim())) {
      return firstLine.trim().replaceFirst(RegExp(r'^#+\s*'), '');
    }
    return null;
  }

  String _extractTitleFromPath(String filePath) {
    final slash = filePath.lastIndexOf('/');
    final dot = filePath.lastIndexOf('.');
    final start = slash < 0 ? 0 : slash + 1;
    final end = dot < 0 ? filePath.length : dot;
    return filePath.substring(start, end).replaceAll('_', ' ');
  }
}
