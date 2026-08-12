import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/content_block.dart';
import '../../domain/entities/user_settings.dart';
import '../engine/rsvp_engine.dart';
import '../engine/rsvp_scheduler.dart';

/// Provides a fresh [RsvpEngine] instance. The engine is created per reading
/// session — not a singleton — because each document needs its own state.
final rsvpEngineProvider = Provider<RsvpEngineFactory>((ref) {
  return RsvpEngineFactory();
});

class RsvpEngineFactory {
  RsvpEngine create({
    required TickerProvider vsync,
  required List<ContentBlock> blocks,
    required RsvpSettings settings,
    int startBlock = 0,
  RsvpScheduler? scheduler,
  }) {
    final sched = scheduler ?? TickerScheduler(vsync);
    final engine = RsvpEngine(scheduler: sched);
    engine.load(blocks: blocks, settings: settings, startBlock: startBlock);
    return engine;
  }
}
