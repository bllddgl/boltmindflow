import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/di/data_providers.dart';
import '../../domain/entities/document.dart';
import '../../domain/result.dart';

/// Library view state.
sealed class LibraryState {
  const LibraryState();
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  const LibraryLoaded(this.documents, {this.includeArchived = false});
  final List<Document> documents;
  final bool includeArchived;
}

class LibraryError extends LibraryState {
  const LibraryError(this.message);
  final String message;
}

/// Sort order for the library list.
enum LibrarySort { recent, imported, title }

/// Notifier that manages the library list.
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._ref) : super(const LibraryInitial()) {
    _ref.read(documentRepositoryProvider);
  }

  final Ref _ref;

  LibrarySort _sort = LibrarySort.recent;
  String _searchQuery = '';

  LibrarySort get sort => _sort;
  String get searchQuery => _searchQuery;

  Future<void> load({bool includeArchived = false}) async {
    state = const LibraryLoading();
    final repo = _ref.read(documentRepositoryProvider);
    final result = await repo.getAll(includeArchived: includeArchived);
    result.when(
      success: (docs) => state = LibraryLoaded(_applySortAndFilter(docs), includeArchived: includeArchived),
      failure: (f) => state = LibraryError(f.message),
    );
  }

  void setSort(LibrarySort s) {
    _sort = s;
    if (state is LibraryLoaded) {
      final loaded = state as LibraryLoaded;
      state = LibraryLoaded(_applySortAndFilter(loaded.documents), includeArchived: loaded.includeArchived);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (state is LibraryLoaded) {
      final loaded = state as LibraryLoaded;
      state = LibraryLoaded(_applySortAndFilter(loaded.documents), includeArchived: loaded.includeArchived);
    }
  }

  Future<void> importDocument({
    required String filePath,
    required String title,
    String? author,
    required String format,
  }) async {
    final repo = _ref.read(documentRepositoryProvider);
    final parser = _ref.read(parserRegistryProvider);

    if (!parser.supports(filePath)) {
      state = const LibraryError('Unsupported file format');
      return;
    }

    final parseResult = await parser.parse(filePath);
    final parsed = parseResult.when(
      success: (output) => output,
      failure: (f) => null,
    );

    if (parsed == null) {
      state = const LibraryError('Could not parse document');
      return;
    }

    final importResult = await repo.importDocument(
      filePath: filePath,
      title: parsed.title.isNotEmpty ? parsed.title : title,
      author: parsed.author ?? author,
      format: format,
    );

    importResult.when(
      success: (doc) async {
        await repo.cacheContent(doc.id, parsed.blocks);
        await load(includeArchived: (state as LibraryLoaded?)?.includeArchived ?? false);
      },
      failure: (f) => state = LibraryError(f.message),
    );
  }

  Future<void> deleteDocument(String id) async {
    final repo = _ref.read(documentRepositoryProvider);
    final result = await repo.deleteDocument(id);
    result.when(
      success: (_) => load(includeArchived: (state as LibraryLoaded?)?.includeArchived ?? false),
      failure: (f) => state = LibraryError(f.message),
    );
  }

  Future<void> archiveDocument(String id, {required bool archived}) async {
    final repo = _ref.read(documentRepositoryProvider);
    final result = await repo.archiveDocument(id, archived: archived);
    result.when(
      success: (_) => load(includeArchived: (state as LibraryLoaded?)?.includeArchived ?? false),
      failure: (f) => state = LibraryError(f.message),
    );
  }

  List<Document> _applySortAndFilter(List<Document> docs) {
    var filtered = docs.where((d) {
      if (_searchQuery.isEmpty) return true;
      return d.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sort) {
      case LibrarySort.recent:
        filtered.sort((a, b) => (b.lastReadAt ?? b.importedAt).compareTo(a.lastReadAt ?? a.importedAt));
      case LibrarySort.imported:
        filtered.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      case LibrarySort.title:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return filtered;
  }
}

final libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final notifier = LibraryNotifier(ref);
  notifier.load();
  return notifier;
});
