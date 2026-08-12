import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/domain/entities/content_block.dart';
import 'package:mindflow/domain/result.dart';

void main() {
  group('Result', () {
    test('success carries value', () {
      final r = Result.success(42);
      expect(r.unwrap(), 42);
    });

    test('when branches correctly', () {
      const r = Result<String>.failure(OfflineFailure());
      final out = r.when(
        success: (v) => 'ok: $v',
        failure: (f) => 'err: ${f.message}',
      );
      expect(out, 'err: This feature needs a network connection.');
    });

    test('unwrap on failure throws', () {
      const r = Result<int>.failure(UnknownFailure());
      expect(() => r.unwrap(), throwsStateError);
    });
  });

  group('ContentBlock wordCount', () {
    test('ParagraphBlock counts words', () {
      const block = ParagraphBlock(text: 'The quick brown fox jumps');
      expect(block.wordCount, 5);
    });

    test('HeadingBlock counts words', () {
      const block = HeadingBlock(text: 'Chapter One', level: 1);
      expect(block.wordCount, 2);
    });

    test('ListBlock sums items', () {
      const block = ListBlock(
        ordered: false,
        items: [
          ListItem(text: 'first item'),
          ListItem(text: 'second item here'),
        ],
      );
      expect(block.wordCount, 5);
    });

    test('CodeBlock counts tokens', () {
      const block = CodeBlock(code: 'void main() { print(42); }');
      expect(block.wordCount, 5);
    });

    test('ImageBlock counts as one', () {
      const block = ImageBlock(assetPath: '/tmp/img.png');
      expect(block.wordCount, 1);
    });

    test('empty text is zero words', () {
      const block = ParagraphBlock(text: '   ');
      expect(block.wordCount, 0);
    });
  });
}
