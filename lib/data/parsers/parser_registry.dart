import '../../domain/entities/content_block.dart';
import '../../domain/result.dart';
import '../../core/errors/failures.dart';

/// Output of a successful parse.
class ParseOutput {
  const ParseOutput({
    required this.blocks,
    required this.title,
    this.author,
    required this.wordCount,
    required this.parseConfidence,
    this.coverPath,
  });

  final List<ContentBlock> blocks;
  final String title;
  final String? author;
  final int wordCount;
  final double parseConfidence; // 0..1
  final String? coverPath;
}

/// Abstract parser interface. Each format implements this.
abstract class DocumentParser {
  /// The file extensions this parser handles (without dot), e.g. `['txt']`.
  List<String> get supportedExtensions;

  /// Parse the file at [filePath] into content blocks.
  Future<Result<ParseOutput>> parse(String filePath);
}

/// Registry that maps file extensions to parsers.
///
/// The import flow picks a parser by extension. Adding a format = one new
/// parser class + one [register] call in the DI setup.
class ParserRegistry {
  ParserRegistry._();

  final Map<String, DocumentParser> _parsers = {};

  void register(DocumentParser parser) {
    for (final ext in parser.supportedExtensions) {
      _parsers[ext.toLowerCase()] = parser;
    }
  }

  /// Returns the parser for [filePath]'s extension, or null if unsupported.
  DocumentParser? parserFor(String filePath) {
    final ext = _extractExtension(filePath);
    return _parsers[ext];
  }

  /// Returns true if any parser handles this file's extension.
  bool supports(String filePath) => parserFor(filePath) != null;

  /// Parse [filePath], auto-selecting the parser by extension.
  Future<Result<ParseOutput>> parse(String filePath) async {
    final parser = parserFor(filePath);
    if (parser == null) return const Result.failure(UnsupportedFormatFailure());
    return parser.parse(filePath);
  }

  String _extractExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
