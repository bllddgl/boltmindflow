/// A user-placed bookmark at a specific block index in a document.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.blockIndex,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final String documentId;
  final int blockIndex;
  final String? label;
  final DateTime createdAt;
}
