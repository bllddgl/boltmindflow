/*
# Create MindFlow core schema (single-tenant, no auth)

1. Purpose
   MindFlow is an AI-powered reading and learning app. This migration creates
   the full data model for documents, parsed content, bookmarks, reading
   sessions, spaced-repetition review cards, AI artifacts, stats events, and
   user settings. The app is single-tenant (no sign-in screen), so all tables
   use anon+authenticated policies with no user_id ownership checks.

2. New Tables
   - documents: library entries (one per imported file)
   - bookmarks: user-placed bookmarks within a document
   - reading_sessions: one row per play-to-pause reading session
   - review_cards: spaced-repetition cards (SM-2 algorithm state)
   - ai_artifacts: cached AI-generated summaries, quizzes, Q&A, etc.
   - stats_events: raw event log for stats aggregation
   - user_settings: single-row app settings (theme, WPM, language, etc.)

3. Content Storage
   - Document content is stored as a JSONB array in documents.content_blocks.
     Each element is a serialized ContentBlock (heading, paragraph, list,
     table, quote, code, image, footnote, caption, formula). This lets the
     reader fetch the entire document in one query without a join table.

4. Security
   - RLS enabled on every table.
   - All policies use TO anon, authenticated (single-tenant, no sign-in).
   - USING (true) / WITH CHECK (true) is acceptable because the data is
     intentionally shared/public within this single-tenant app.

5. Indexes
   - documents: imported_at (sort), is_archived (filter)
   - bookmarks: document_id (lookup)
   - reading_sessions: document_id (lookup), started_at (sort)
   - review_cards: due_at (due-today query)
   - ai_artifacts: document_id (lookup)
   - stats_events: created_at (time-window aggregation)
*/

-- ============================================================================
-- documents
-- ============================================================================
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  author text,
  source_path text NOT NULL,
  source_format text NOT NULL DEFAULT 'txt',
  word_count integer NOT NULL DEFAULT 0,
  cover_path text,
  parse_confidence double precision NOT NULL DEFAULT 1.0,
  content_blocks jsonb DEFAULT '[]'::jsonb,
  imported_at timestamptz NOT NULL DEFAULT now(),
  last_position integer NOT NULL DEFAULT 0,
  last_read_at timestamptz,
  is_archived boolean NOT NULL DEFAULT false
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_documents" ON documents;
CREATE POLICY "anon_select_documents" ON documents FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_documents" ON documents;
CREATE POLICY "anon_insert_documents" ON documents FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_documents" ON documents;
CREATE POLICY "anon_update_documents" ON documents FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_documents" ON documents;
CREATE POLICY "anon_delete_documents" ON documents FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_documents_imported_at ON documents (imported_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_is_archived ON documents (is_archived);

-- ============================================================================
-- bookmarks
-- ============================================================================
CREATE TABLE IF NOT EXISTS bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  block_index integer NOT NULL,
  label text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_bookmarks" ON bookmarks;
CREATE POLICY "anon_select_bookmarks" ON bookmarks FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_bookmarks" ON bookmarks;
CREATE POLICY "anon_insert_bookmarks" ON bookmarks FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_bookmarks" ON bookmarks;
CREATE POLICY "anon_update_bookmarks" ON bookmarks FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_bookmarks" ON bookmarks;
CREATE POLICY "anon_delete_bookmarks" ON bookmarks FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_bookmarks_document_id ON bookmarks (document_id);

-- ============================================================================
-- reading_sessions
-- ============================================================================
CREATE TABLE IF NOT EXISTS reading_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  words_read integer NOT NULL DEFAULT 0,
  blocks_read integer NOT NULL DEFAULT 0,
  avg_wpm integer NOT NULL DEFAULT 0,
  focus_score double precision NOT NULL DEFAULT 1.0
);

ALTER TABLE reading_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_reading_sessions" ON reading_sessions;
CREATE POLICY "anon_select_reading_sessions" ON reading_sessions FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_reading_sessions" ON reading_sessions;
CREATE POLICY "anon_insert_reading_sessions" ON reading_sessions FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_reading_sessions" ON reading_sessions;
CREATE POLICY "anon_update_reading_sessions" ON reading_sessions FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_reading_sessions" ON reading_sessions;
CREATE POLICY "anon_delete_reading_sessions" ON reading_sessions FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_reading_sessions_document_id ON reading_sessions (document_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_started_at ON reading_sessions (started_at DESC);

-- ============================================================================
-- review_cards
-- ============================================================================
CREATE TABLE IF NOT EXISTS review_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  card_type text NOT NULL DEFAULT 'flashcard',
  front text NOT NULL,
  back text NOT NULL,
  ease double precision NOT NULL DEFAULT 2.5,
  interval_days integer NOT NULL DEFAULT 0,
  repetitions integer NOT NULL DEFAULT 0,
  due_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE review_cards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_review_cards" ON review_cards;
CREATE POLICY "anon_select_review_cards" ON review_cards FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_review_cards" ON review_cards;
CREATE POLICY "anon_insert_review_cards" ON review_cards FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_review_cards" ON review_cards;
CREATE POLICY "anon_update_review_cards" ON review_cards FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_review_cards" ON review_cards;
CREATE POLICY "anon_delete_review_cards" ON review_cards FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_review_cards_due_at ON review_cards (due_at);
CREATE INDEX IF NOT EXISTS idx_review_cards_document_id ON review_cards (document_id);

-- ============================================================================
-- ai_artifacts
-- ============================================================================
CREATE TABLE IF NOT EXISTS ai_artifacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  artifact_type text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  model_id text,
  token_cost integer,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE ai_artifacts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_ai_artifacts" ON ai_artifacts;
CREATE POLICY "anon_select_ai_artifacts" ON ai_artifacts FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_ai_artifacts" ON ai_artifacts;
CREATE POLICY "anon_insert_ai_artifacts" ON ai_artifacts FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_ai_artifacts" ON ai_artifacts;
CREATE POLICY "anon_update_ai_artifacts" ON ai_artifacts FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_ai_artifacts" ON ai_artifacts;
CREATE POLICY "anon_delete_ai_artifacts" ON ai_artifacts FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_ai_artifacts_document_id ON ai_artifacts (document_id);

-- ============================================================================
-- stats_events
-- ============================================================================
CREATE TABLE IF NOT EXISTS stats_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  document_id uuid REFERENCES documents(id) ON DELETE SET NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE stats_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_stats_events" ON stats_events;
CREATE POLICY "anon_select_stats_events" ON stats_events FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_stats_events" ON stats_events;
CREATE POLICY "anon_insert_stats_events" ON stats_events FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_stats_events" ON stats_events;
CREATE POLICY "anon_update_stats_events" ON stats_events FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_stats_events" ON stats_events;
CREATE POLICY "anon_delete_stats_events" ON stats_events FOR DELETE
  TO anon, authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_stats_events_created_at ON stats_events (created_at DESC);

-- ============================================================================
-- user_settings (single-row table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_settings (
  id integer PRIMARY KEY DEFAULT 1,
  theme_mode text NOT NULL DEFAULT 'light',
  locale text,
  font_scale double precision NOT NULL DEFAULT 1.0,
  target_wpm integer NOT NULL DEFAULT 400,
  words_per_display integer NOT NULL DEFAULT 1,
  line_count integer NOT NULL DEFAULT 1,
  image_duration_ms integer NOT NULL DEFAULT 2000,
  adaptive_speed boolean NOT NULL DEFAULT false,
  has_onboarded boolean NOT NULL DEFAULT false,
  CONSTRAINT single_row CHECK (id = 1)
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_user_settings" ON user_settings;
CREATE POLICY "anon_select_user_settings" ON user_settings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_user_settings" ON user_settings;
CREATE POLICY "anon_insert_user_settings" ON user_settings FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_user_settings" ON user_settings;
CREATE POLICY "anon_update_user_settings" ON user_settings FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_user_settings" ON user_settings;
CREATE POLICY "anon_delete_user_settings" ON user_settings FOR DELETE
  TO anon, authenticated USING (true);

-- Seed the single settings row
INSERT INTO user_settings (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;