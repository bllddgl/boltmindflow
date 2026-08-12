# MindFlow

**Read faster. Understand more. Remember longer.**

MindFlow is an AI-powered reading and learning platform. It uses RSVP (Rapid Serial Visual Presentation) to deliver documents at the user's target speed, an adaptive engine that slows for hard content and pauses for structure, and an optional AI layer that generates summaries, quizzes, and Q&A to close the read → understand → remember loop.

## Architecture

Clean Architecture with a strict dependency direction:

```
presentation  ──▶  domain  ◀──  data
   (UI)          (logic)       (I/O)
```

- **domain/** — pure Dart. Entities, repository interfaces, use cases. No Flutter, no Riverpod, no SQLite.
- **data/** — implements domain interfaces. SQLite, Hive, file I/O, parsers, AI clients.
- **presentation/** — Flutter + Riverpod. Feature-first folders, each self-contained.
- **core/** — shared kernel (theme, router, responsive, DI composition root, errors).

Two planes:
- **Offline plane** (always available): reading, RSVP, bookmarks, history, stats, SRS review. Backed by SQLite + Hive.
- **Online plane** (optional, lazy): AI features, future cloud sync. Behind repository interfaces so the offline app never blocks on it.

## Tech stack

- Flutter (latest stable), Android first — architected for Windows, iOS, Web
- Riverpod 2.x (state management + DI)
- GoRouter (navigation, StatefulShellRoute for adaptive nav)
- Material 3 (light / dark / sepia themes)
- SQLite (relational data) + Hive (key-value blobs)
- Feature-first folder structure, repository pattern, offline-first

## Module map

| Module | Status | Path |
|--------|--------|------|
| 1 — Scaffold + DI + router + theme | ✅ | `lib/core/` |
| 2 — Domain layer | ⏳ | `lib/domain/` |
| 3 — Data layer: database | ⏳ | `lib/data/` |
| 4 — Data layer: parsers | ⏳ | `lib/data/parsers/` |
| 5 — RSVP engine | ⏳ | `lib/domain/rsvp/` or `lib/core/rsvp/` |
| 6 — Theme + responsive shell + router | ✅ (in core) | `lib/core/` |
| 7 — Library feature | ⏳ | `lib/presentation/features/library/` |
| 8 — Reader feature | ⏳ | `lib/presentation/features/reader/` |
| 9 — Review feature | ⏳ | `lib/presentation/features/review/` |
| 10 — Stats feature | ⏳ | `lib/presentation/features/stats/` |
| 11 — AI feature | ⏳ | `lib/presentation/features/ai/` |
| 12 — Settings + Onboarding + Paywall | ⏳ | `lib/presentation/features/` |
| 13 — Tests | partial | `test/` |

## Building

> Flutter/Dart are not installed in this sandbox. To build:
>
> ```
> flutter pub get
> flutter run           # Android (default target)
> flutter run -d chrome # Web
> flutter run -d windows # Windows
> ```

## License

Proprietary — MindFlow.
