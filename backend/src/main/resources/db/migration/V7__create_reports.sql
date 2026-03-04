-- V7: Reports table — the core entity of CityVoice

CREATE TABLE reports (
    id                      UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- The authenticated citizen who submitted the report
    citizen_id              UUID            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

    -- Category (FK to configurable categories table)
    category_id             INTEGER         NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,

    -- Priority is set by staff during review (NULL until staff assigns)
    priority                priority_level,

    title                   VARCHAR(500)    NOT NULL,
    description             TEXT,

    -- Geospatial point in WGS84 — validated to fall within HCMC boundary on insert
    location                GEOGRAPHY(POINT, 4326) NOT NULL,

    -- Denormalized zone for fast filtering (auto-assigned on insert via spatial join)
    administrative_zone_id  INTEGER         REFERENCES administrative_zones(id) ON DELETE SET NULL,

    -- Cloud Storage URL for citizen's incident photo (required)
    incident_image_url      TEXT            NOT NULL,

    -- Cloud Storage URL for staff's resolution proof photo (set when resolved)
    resolution_image_url    TEXT,

    -- Current status — single source of truth cached here for query performance.
    -- Full audit trail lives in status_history.
    current_status          report_status   NOT NULL DEFAULT 'newly_received',

    -- Staff member currently assigned to handle this report
    assigned_to             UUID            REFERENCES users(id) ON DELETE SET NULL,

    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Set when transitioned to 'resolved'
    resolved_at             TIMESTAMPTZ
);

-- Indexes for common query patterns
CREATE INDEX idx_reports_citizen_id        ON reports(citizen_id);
CREATE INDEX idx_reports_category_id       ON reports(category_id);
CREATE INDEX idx_reports_current_status    ON reports(current_status);
CREATE INDEX idx_reports_priority          ON reports(priority);
CREATE INDEX idx_reports_admin_zone_id     ON reports(administrative_zone_id);
CREATE INDEX idx_reports_assigned_to       ON reports(assigned_to);
CREATE INDEX idx_reports_created_at        ON reports(created_at);
-- Spatial index for heatmap aggregation and zone-level filtering
CREATE INDEX idx_reports_location          ON reports USING GIST(location);
