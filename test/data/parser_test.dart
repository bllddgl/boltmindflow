import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/data/parsers/difficulty_heuristic.dart';
import 'package:mindflow/data/parsers/txt_parser.dart';
import 'package:mindflow/domain/entities/content_block.dart';

void main() {
  group('TxtParser.parseContent', () {
    final parser = TxtParser();

    test('parses simple paragraphs', () {
      const content = 'This is the first paragraph.\n\nThis is the second.';
      final result = parser.parseContent(content, 'test.txt');

      expect(result.when(success: (v) => v, failure: (_) => null)?.blocks.length, 2);
    });

    test('detects markdown headings', () {
      const content = '# Chapter 1\n\nSome text here.';
      final output = parser.parseContent(content, 'test.txt').unwrap();

      expect(output.blocks.first, isA<HeadingBlock>());
      final heading = output.blocks.first as HeadingBlock;
      expect(heading.level, 1);
      expect(heading.text, 'Chapter 1');
    });

    test('detects ALL CAPS headings', () {
      const content = 'INTRODUCTION\n\nThe body text follows here.';
      final output = parser.parseContent(content, 'test.txt').unwrap();

      expect(output.blocks.first, isA<HeadingBlock>());
    });

    test('detects bullet lists', () {
      const content = '- First item\n- Second item\n- Third item';
      final output = parser.parseContent(content, 'test.txt').unwrap();

      expect(output.blocks.first, isA<ListBlock>());
      final list = output.blocks.first as ListBlock;
      expect(list.ordered, isFalse);
      expect(list.items.length, 3);
    });

    test('detects ordered lists', () {
      const content = '1. First\n2. Second\n3. Third';
      final output = parser.parseContent(content, 'test.txt').unwrap();

      expect(output.blocks.first, isA<ListBlock>());
      final list = output.blocks.first as ListBlock;
      expect(list.ordered, isTrue);
      expect(list.items.length, 3);
    }

    test('extracts title from first heading', () {
      const content = '# My Book Title\n\nSome content.';
      final output = parser.parseContent(content, 'test.txt').unwrap();
      expect(output.title, 'My Book Title');
    });

    test('falls back to filename for title', () {
      const content = 'Just some text without a heading.';
      final output = parser.parseContent(content, 'my_book.txt').unwrap();
      expect(output.title, 'my book');
    });

    test('empty content returns failure', () {
      const content = '   ';
      final result = parser.parseContent(content, 'test.txt');
      expect(result.when(success: (_) => 'ok', failure: (_) => 'fail'), 'fail');
    });

    test('counts words correctly', () {
      const content = 'One two three four five.';
      final output = parser.parseContent(content, 'test.txt').unwrap();
      expect(output.wordCount, 5);
    });
  });

  group('estimateDifficulty', () {
    test('short simple words are easy', () {
      expect(estimateDifficulty('The cat sat on the mat.'), Difficulty.easy);
    });

    test('long academic words are hard', () {
      expect(
        estimateDifficulty(
          'The phenomenological investigation demonstrated considerable '
          'methodological sophistication throughout the experimental '
          'apparatus.',
        ),
        Difficulty.hard,
      );
    });

    test('empty text is easy', () {
      expect(estimateDifficulty(''), Difficulty.easy);
    });
  });
}
