-- V9: Notifications table
-- Supports both in-app and email notifications.
-- Triggered by status transitions (e.g., report_resolved → notifies citizen)

CREATE TABLE notifications (
    id          UUID                    PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Recipient of the notification
    user_id     UUID                    NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- The report this notification relates to (nullable for system-wide notifications)
    report_id   UUID                    REFERENCES reports(id) ON DELETE CASCADE,

    -- Notification type identifier for frontend rendering
    -- e.g. 'report_resolved', 'report_in_progress', 'report_rejected', 'report_assigned'
    type        VARCHAR(100)            NOT NULL,

    -- Delivery channel
    channel     notification_channel    NOT NULL,

    -- Pre-rendered message body (plain text or HTML for email)
    message     TEXT                    NOT NULL,

    -- In-app read status
    is_read     BOOLEAN                 NOT NULL DEFAULT FALSE,

    -- NULL = queued/pending dispatch; set to NOW() when actually sent
    sent_at     TIMESTAMPTZ,

    created_at  TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id   ON notifications(user_id);
CREATE INDEX idx_notifications_report_id ON notifications(report_id);
CREATE INDEX idx_notifications_is_read   ON notifications(is_read);
CREATE INDEX idx_notifications_sent_at   ON notifications(sent_at) WHERE sent_at IS NULL;
