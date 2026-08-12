import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/engine/rsvp_engine.dart';
import 'package:mindflow/core/engine/rsvp_events.dart';
import 'package:mindflow/core/engine/rsvp_scheduler.dart';
import 'package:mindflow/domain/entities/content_block.dart';
import 'package:mindflow/domain/entities/user_settings.dart';

void main() {
  late FakeScheduler scheduler;
  late RsvpEngine engine;

  setUp(() {
    scheduler = FakeScheduler();
    engine = RsvpEngine(scheduler: scheduler);
  });

  tearDown(() {
    engine.dispose();
  });

  RsvpEngine createEngine(List<ContentBlock> blocks, {RsvpSettings? settings}) {
    final e = RsvpEngine(scheduler: scheduler);
    e.load(blocks: blocks, settings: settings ?? RsvpSettings.defaults());
    return e;
  }

  group('state machine', () {
    test('starts in idle state', () {
      expect(engine.state, RsvpState.idle);
    });

    test('play transitions to playing', () {
      engine.load(
        blocks: [const ParagraphBlock(text: 'Hello world')],
        settings: RsvpSettings.defaults(),
      );
      engine.play();
      expect(engine.state, RsvpState.playing);
    });

    test('pause transitions to paused', () {
      engine.load(
        blocks: [const ParagraphBlock(text: 'Hello world')],
        settings: RsvpSettings.defaults(),
      );
      engine.play();
      engine.pause();
      expect(engine.state, RsvpState.paused);
    });

    test('resume from paused transitions to playing', () {
      engine.load(
        blocks: [const ParagraphBlock(text: 'Hello world')],
        settings: RsvpSettings.defaults(),
      );
      engine.play();
      engine.pause();
      engine.play();
      expect(engine.state, RsvpState.playing);
    });

    test('play after finished throws', () {
      engine.load(
        blocks: [const ParagraphBlock(text: 'Hello')],
        settings: RsvpSettings.defaults(),
      );
      engine.play();
      scheduler.fire(); // tick
      scheduler.fire(); // advance block -> finish
      expect(engine.state, RsvpState.finished);
      expect(() => engine.play(), throwsStateError);
    });
  });

  group('word chunking', () {
    test('chunks paragraph by wordsPerDisplay', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const ParagraphBlock(text: 'one two three four five')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 2,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      // First tick: chunk 0 ("one two")
      scheduler.fire();
      expect(events.whereType<TickEvent>().length, 1);
      expect((events.whereType<TickEvent>().first).chunk.words, ['one', 'two']);

      // Second tick: chunk 1 ("three four")
      scheduler.fire();
      expect(events.whereType<TickEvent>().length, 2);
      expect((events.whereType<TickEvent>().last).chunk.words, ['three', 'four']);

      // Third tick: chunk 2 ("five")
      scheduler.fire();
      expect(events.whereType<TickEvent>().length, 3);
      expect((events.whereType<TickEvent>().last).chunk.words, ['five']);
    });

    test('heading block produces single chunk', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const HeadingBlock(text: 'Chapter 1', level: 1)],
        settings: RsvpSettings.defaults(),
      );
      engine.events.listen(events.add);
      engine.play();
      scheduler.fire();

      final tick = events.whereType<TickEvent>().first;
      expect(tick.chunk.words, ['Chapter 1']);
      expect(tick.chunk.blockType, HeadingBlock);
    });
  });

  group('timing', () {
    test('duration is based on WPM', () {
      final e = createEngine([const ParagraphBlock(text: 'one two three four')]);
      e.load(
        blocks: [const ParagraphBlock(text: 'one two three four')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 4,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      e.play();
      // 4 words at 600 WPM = 4/600 * 60s = 0.4s = 400ms
      expect(scheduler.pendingDelay.inMilliseconds, 400);
    });

    test('minimum duration is enforced', () {
      engine.load(
        blocks: [const ParagraphBlock(text: 'a')],
        settings: const RsvpSettings(
          targetWpm: 1500,
          wordsPerDisplay: 1,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.play();
      // 1 word at 1500 WPM = 1/1500 * 60s = 0.04s = 40ms → clamped to 200ms
      expect(scheduler.pendingDelay.inMilliseconds, 200);
    });
  });

  group('adaptive speed', () {
    test('easy difficulty increases WPM (shorter duration)', () {
      final e = createEngine([]);
      e.load(
        blocks: [const ParagraphBlock(text: 'one two three four', difficulty: Difficulty.easy)],
        settings: const RsvpSettings(
          targetWpm: 400,
          wordsPerDisplay: 4,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: true,
        ),
      );
      e.play();
      // 4 words at 440 WPM (400 * 1.1) = 4/440 * 60s ≈ 545ms
      expect(scheduler.pendingDelay.inMilliseconds, closeTo(545, 5));
    });

    test('hard difficulty decreases WPM (longer duration)', () {
      final e = createEngine([]);
      e.load(
        blocks: [const ParagraphBlock(text: 'one two three four', difficulty: Difficulty.hard)],
        settings: const RsvpSettings(
          targetWpm: 400,
          wordsPerDisplay: 4,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: true,
        ),
      );
      e.play();
      // 4 words at 340 WPM (400 * 0.85) = 4/340 * 60s ≈ 706ms
      expect(scheduler.pendingDelay.inMilliseconds, closeTo(706, 5));
    });
  });

  group('rewind and skip', () {
    test('rewind moves position backward', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const ParagraphBlock(text: 'one two three four five six')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 1,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      // Tick 3 chunks forward
      scheduler.fire(); // "one"
      scheduler.fire(); // "two"
      scheduler.fire(); // "three"
      expect(engine.wordsRead, 3);

      // Rewind 2
      engine.rewind(2);

      // Next tick should be "two" again
      scheduler.fire();
      final lastTick = events.whereType<TickEvent>().last;
      expect(lastTick.chunk.words, ['two']);
    });

    test('skip moves position forward', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const ParagraphBlock(text: 'one two three four five')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 1,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      scheduler.fire(); // "one"
      engine.skip(2);

      // Next tick should be "four" (skipped "two" and "three")
      scheduler.fire();
      final lastTick = events.whereType<TickEvent>().last;
      expect(lastTick.chunk.words, ['four']);
    });
  });

  group('stats', () {
    test('computes stats on finish', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const ParagraphBlock(text: 'one two three')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 1,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      scheduler.fire(); // "one"
      scheduler.fire(); // "two"
      scheduler.fire(); // "three"
      scheduler.fire(); // advance block → finish

      final finished = events.whereType<FinishedEvent>().first;
      expect(finished.stats.wordsRead, 3);
      expect(finished.stats.blocksRead, 1);
      expect(finished.stats.focusScore, 1.0);
    });

    test('rewinds lower focus score', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [const ParagraphBlock(text: 'one two three four five')],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 1,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      scheduler.fire();
      scheduler.fire();
      engine.rewind(1);
      scheduler.fire();
      scheduler.fire();
      scheduler.fire();
      scheduler.fire();
      scheduler.fire(); // finish

      final finished = events.whereType<FinishedEvent>().first;
      expect(finished.stats.focusScore, lessThan(1.0));
    });
  });

  group('multi-block', () {
    test('emits BlockChangedEvent when advancing', () {
      final events = <RsvpEvent>[];
      engine.load(
        blocks: [
          const ParagraphBlock(text: 'first block'),
          const ParagraphBlock(text: 'second block'),
        ],
        settings: const RsvpSettings(
          targetWpm: 600,
          wordsPerDisplay: 10,
          lineCount: 1,
          imageDuration: Duration(seconds: 2),
          adaptiveSpeed: false,
        ),
      );
      engine.events.listen(events.add);
      engine.play();

      // First block
      expect(events.whereType<BlockChangedEvent>().length, 1);
      expect(events.whereType<BlockChangedEvent>().first.blockIndex, 0);

      scheduler.fire(); // tick "first block"

      // Should advance to second block
      expect(events.whereType<BlockChangedEvent>().length, 2);
      expect(events.whereType<BlockChangedEvent>().last.blockIndex, 1);

      scheduler.fire(); // tick "second block" → finish
      expect(engine.state, RsvpState.finished);
    });
  });
}
