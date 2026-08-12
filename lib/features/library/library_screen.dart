import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import 'library_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(libraryNotifierProvider);
    final notifier = ref.read(libraryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, notifier),
            tooltip: l.librarySearch,
          ),
          PopupMenuButton<LibrarySort>(
            icon: const Icon(Icons.sort),
            tooltip: l.librarySearch,
            onSelected: notifier.setSort,
            itemBuilder: (_) => [
              PopupMenuItem(value: LibrarySort.recent, child: Text(l.librarySortRecent)),
              PopupMenuItem(value: LibrarySort.imported, child: Text(l.librarySortImported)),
              PopupMenuItem(value: LibrarySort.title, child: Text(l.librarySortTitle)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.load(includeArchived: false),
        child: _buildBody(context, state, l),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importDocument(context, ref),
        icon: const Icon(Icons.upload_file),
        label: Text(l.libraryImport),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state, AppLocalizations l) {
    return switch (state) {
      LibraryInitial() || LibraryLoading() =>
        const Center(child: CircularProgressIndicator()),
      LibraryError(:final message) => _buildError(context, message, l),
      LibraryLoaded(:final documents) when documents.isEmpty =>
        _buildEmpty(context, l),
      LibraryLoaded(:final documents) => _buildList(context, documents, l),
    };
  }

  Widget _buildError(BuildContext context, String message, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(libraryNotifierProvider.notifier).load(),
              child: Text(l.libraryReparse),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(l.libraryEmpty, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.libraryEmptyHint, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List documents, AppLocalizations l) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _DocumentCard(
          document: doc,
          onTap: () => context.push('/reader/${doc.id}'),
          onArchive: () => ref
              .read(libraryNotifierProvider.notifier)
              .archiveDocument(doc.id, archived: !doc.isArchived),
          onDelete: () => _confirmDelete(context, doc.id, l),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.libraryDeleteConfirm),
        content: Text(l.libraryDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(libraryNotifierProvider.notifier).deleteDocument(docId);
            },
            child: Text(l.libraryDelete),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, LibraryNotifier notifier) {
    showSearch(
      context: context,
      delegate: _LibrarySearchDelegate(notifier),
    );
  }

  void _importDocument(BuildContext context, WidgetRef ref) {
    // File picker integration happens in the platform layer.
    // For now, show a snackbar — the import flow is wired via
    // libraryNotifierProvider.notifier.importDocument().
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker integration coming soon')),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final dynamic document;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = document.title as String;
    final author = document.author as String?;
    final format = document.sourceFormat as String;
    final wordCount = document.wordCount as int;
    final progress = document.progress as double;
    final parseConfidence = document.parseConfidence as double;
    final lastReadAt = document.lastReadAt as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FormatBadge(format: format),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (author != null) ...[
                const SizedBox(height: 4),
                Text(author, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: progress, minHeight: 4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).round()}%',
                      style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${(wordCount / 1000).toStringAsFixed(wordCount < 1000 ? 0 : 1)}k words',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  if (parseConfidence < 0.8)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Text('Imperfect', style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error)),
                      ],
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'archive') onArchive();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'archive', child: Text('Archive')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (lastReadAt != null) ...[
                const SizedBox(height: 4),
                Text(_formatDate(lastReadAt), style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({required this.format});
  final String format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        format.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LibrarySearchDelegate extends SearchDelegate {
  _LibrarySearchDelegate(this.notifier);
  final LibraryNotifier notifier;

  @override
  String get searchFieldLabel => 'Search library';

  @override
  Widget buildSuggestions(BuildContext context, String query) {
    notifier.setSearchQuery(query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildResults(BuildContext context, String query) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          notifier.setSearchQuery('');
        },
      ),
    ];
  }
}
