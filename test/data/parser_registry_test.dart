import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/data/parsers/parser_registry.dart';
import 'package:mindflow/data/parsers/txt_parser.dart';
import 'package:mindflow/domain/result.dart';

void main() {
  group('ParserRegistry', () {
    late ParserRegistry registry;

    setUp(() {
      registry = ParserRegistry._();
      registry.register(TxtParser());
    });

    test('supports returns true for registered extensions', () {
      expect(registry.supports('document.txt'), isTrue);
    });

    test('supports returns false for unregistered extensions', () {
      expect(registry.supports('document.pdf'), isFalse);
    });

    test('supports returns false for files with no extension', () {
      expect(registry.supports('document'), isFalse);
    });

    test('parserFor returns parser for known extension', () {
      expect(registry.parserFor('test.txt'), isNotNull);
    });

    test('parserFor returns null for unknown extension', () {
      expect(registry.parserFor('test.pdf'), isNull);
    });

    test('parserFor is case-insensitive on extension', () {
      expect(registry.parserFor('test.TXT'), isNotNull);
    });

    test('parse returns failure for unsupported format', () async {
      final result = await registry.parse('document.xyz');
      expect(result.when(success: (_) => 'ok', failure: (_) => 'fail'), 'fail');
    });

    test('parse returns failure for file with no extension', () async {
      final result = await registry.parse('document');
      expect(result.when(success: (_) => 'ok', failure: (_) => 'fail'), 'fail');
    });

    test('extension extraction handles trailing dot', () {
      expect(registry.parserFor('file.'), isNull);
    });
  });
}
