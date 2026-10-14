-- Copyright (c) 2026 [Your Name]. All rights reserved.
-- SPDX-License-Identifier: LicenseRef-Proprietary
-- Commercial licensing: [your future site]
--
-- Complete schema. Every statement uses IF NOT EXISTS — idempotent on every startup.

-- ── profiles ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          TEXT NOT NULL,
  tenant_id   TEXT NOT NULL DEFAULT 'default',
  name        TEXT NOT NULL,
  description TEXT,
  color       TEXT,
  icon        TEXT,
  is_default  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL DEFAULT (unixepoch()),
  archived_at INTEGER,
  PRIMARY KEY (id, tenant_id),
  UNIQUE (name, tenant_id)
);

-- ── nodes ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS nodes (
  id                TEXT NOT NULL,
  tenant_id         TEXT NOT NULL DEFAULT 'default',
  profile           TEXT NOT NULL DEFAULT 'global',
  type              TEXT NOT NULL CHECK(type IN (
                      'fact','decision','mistake','pattern','context','preference'
                    )),
  namespace         TEXT NOT NULL DEFAULT 'general',
  summary           TEXT NOT NULL,
  content           TEXT NOT NULL,
  tags              TEXT NOT NULL DEFAULT '[]',
  source_ai         TEXT,
  confidence        REAL NOT NULL DEFAULT 1.0,

  tier              TEXT NOT NULL DEFAULT 'medium'
                    CHECK(tier IN ('short','medium','long','archived')),
  session_id        TEXT,
  ttl_seconds       INTEGER,
  recall_count      INTEGER NOT NULL DEFAULT 0,
  last_recalled_at  INTEGER,
  promoted_at       INTEGER,
  archived_at       INTEGER,
  archive_delete_at INTEGER,

  valid_from        INTEGER NOT NULL DEFAULT (unixepoch()),
  valid_until       INTEGER,
  recorded_at       INTEGER NOT NULL DEFAULT (unixepoch()),

  is_mistake        INTEGER NOT NULL DEFAULT 0,
  do_not_do         TEXT,
  mistake_fix       TEXT,

  PRIMARY KEY (id, tenant_id),
  FOREIGN KEY (profile, tenant_id) REFERENCES profiles(name, tenant_id)
);

-- ── edges ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS edges (
  id          TEXT NOT NULL,
  tenant_id   TEXT NOT NULL DEFAULT 'default',
  from_id     TEXT NOT NULL,
  to_id       TEXT NOT NULL,
  relation    TEXT NOT NULL CHECK(relation IN (
                'caused','supersedes','related_to',
                'contradicts','depends_on','derived_from'
              )),
  weight      REAL NOT NULL DEFAULT 1.0,
  created_at  INTEGER NOT NULL DEFAULT (unixepoch()),
  PRIMARY KEY (id, tenant_id),
  FOREIGN KEY (from_id, tenant_id) REFERENCES nodes(id, tenant_id) ON DELETE CASCADE,
  FOREIGN KEY (to_id,   tenant_id) REFERENCES nodes(id, tenant_id) ON DELETE CASCADE
);

-- ── tags ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tags (
  tag        TEXT NOT NULL,
  node_id    TEXT NOT NULL,
  tenant_id  TEXT NOT NULL DEFAULT 'default',
  profile    TEXT NOT NULL DEFAULT 'global',
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  PRIMARY KEY (tag, node_id, tenant_id),
  FOREIGN KEY (node_id, tenant_id) REFERENCES nodes(id, tenant_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tags_tag     ON tags(tenant_id, tag);
CREATE INDEX IF NOT EXISTS idx_tags_node    ON tags(tenant_id, node_id);
CREATE INDEX IF NOT EXISTS idx_tags_profile ON tags(tenant_id, profile, tag);

-- ── memory_queue ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS memory_queue (
  id               TEXT NOT NULL,
  tenant_id        TEXT NOT NULL DEFAULT 'default',
  node_id          TEXT NOT NULL,
  profile          TEXT NOT NULL DEFAULT 'global',
  action           TEXT NOT NULL CHECK(action IN ('promote','purge')),
  from_tier        TEXT NOT NULL,
  to_tier          TEXT,
  reason           TEXT NOT NULL,
  recall_count     INTEGER,
  last_recalled_at INTEGER,
  proposed_at      INTEGER NOT NULL DEFAULT (unixepoch()),
  expires_at       INTEGER NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK(status IN ('pending','confirmed','rejected','expired')),
  PRIMARY KEY (id, tenant_id)
);

-- ── enrichment_queue ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS enrichment_queue (
  id             TEXT NOT NULL,
  tenant_id      TEXT NOT NULL DEFAULT 'default',
  node_id        TEXT NOT NULL,
  profile        TEXT NOT NULL DEFAULT 'global',
  suggested_tags TEXT NOT NULL,
  current_tags   TEXT NOT NULL,
  proposed_by    TEXT,
  proposed_at    INTEGER NOT NULL DEFAULT (unixepoch()),
  expires_at     INTEGER NOT NULL,
