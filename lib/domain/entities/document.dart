/// A document in the user's library.
///
/// Immutable snapshot of the library row. Reading-position state
/// ([lastPosition], [lastReadAt]) is denormalized here for fast "continue
/// reading" access without joining reading_sessions.
class Document {
  const Document({
    required this.id,
    required this.title,
    required this.author,
    required this.sourcePath,
    required this.sourceFormat,
    required this.wordCount,
    required this.coverPath,
    required this.parseConfidence,
    required this.importedAt,
    required this.lastPosition,
    required this.lastReadAt,
    required this.isArchived,
  });

  final String id;
  final String title;
  final String? author;
  final String sourcePath;
  final String sourceFormat; // 'txt' | 'epub' | 'pdf' | ...
  final int wordCount;
  final String? coverPath;
  final double parseConfidence; // 0..1
  final DateTime importedAt;
  final int lastPosition; // block index
  final DateTime? lastReadAt;
  final bool isArchived;

  double get progress => wordCount == 0 ? 0 : (lastPosition / wordCount).clamp(0.0, 1.0);

  Document copyWith({
    String? title,
    int? lastPosition,
    DateTime? lastReadAt,
    bool? isArchived,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      author: author,
      sourcePath: sourcePath,
      sourceFormat: sourceFormat,
      wordCount: wordCount,
      coverPath: coverPath,
      parseConfidence: parseConfidence,
      importedAt: importedAt,
      lastPosition: lastPosition ?? this.lastPosition,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
