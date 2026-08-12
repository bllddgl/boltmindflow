import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/features/library/library_providers.dart';

void main() {
  group('LibrarySort', () {
    test('has three sort options', () {
      expect(LibrarySort.values.length, 3);
      expect(LibrarySort.values, contains(LibrarySort.recent));
      expect(LibrarySort.values, contains(LibrarySort.imported));
      expect(LibrarySort.values, contains(LibrarySort.title));
    });
  });

  group('LibraryState', () {
    test('initial state is LibraryInitial', () {
      expect(const LibraryInitial(), isA<LibraryState>());
    });

    test('loading state is LibraryLoading', () {
      expect(const LibraryLoading(), isA<LibraryState>());
    });

    test('loaded state contains documents', () {
      const state = LibraryLoaded([], includeArchived: false);
      expect(state.documents, isEmpty);
      expect(state.includeArchived, isFalse);
    });

    test('error state contains message', () {
      const state = LibraryError('Something went wrong');
      expect(state.message, 'Something went wrong');
    });
  });
}
