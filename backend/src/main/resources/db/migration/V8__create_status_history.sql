-- V8: Status history table — serves dual purpose:
--   1. Audit log: full immutable record of every state change on every report
--   2. State machine enforcement support: backend reads this to validate transitions

CREATE TABLE status_history (
    id          UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id   UUID            NOT NULL REFERENCES reports(id) ON DELETE CASCADE,

    -- The user (staff/system) who performed this state change
    changed_by  UUID            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

    -- NULL only for the initial 'newly_received' entry (no previous state)
    from_status report_status,
    to_status   report_status   NOT NULL,

    -- Optional context: rejection reason, resolution notes, etc.
    note        TEXT,

    changed_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_status_history_report_id  ON status_history(report_id);
CREATE INDEX idx_status_history_changed_by ON status_history(changed_by);
CREATE INDEX idx_status_history_changed_at ON status_history(changed_at);
