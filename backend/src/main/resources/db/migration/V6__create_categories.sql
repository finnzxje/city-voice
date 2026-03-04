-- V6: Categories table (dynamic, configurable by admin)
-- Replaces a hardcoded enum so new categories can be added without DB migrations

CREATE TABLE categories (
    id          SERIAL       PRIMARY KEY,
    -- Display name: "Pothole", "Broken Streetlight"
    name        VARCHAR(100) NOT NULL,
    -- URL-safe slug: "pothole", "broken-streetlight"
    slug        VARCHAR(100) UNIQUE NOT NULL,
    -- Frontend icon reference key (e.g. maps to a Lucide/Material icon name)
    icon_key    VARCHAR(100),
    -- Soft-delete: hide from citizen UI without deleting historical data
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_slug      ON categories(slug);
CREATE INDEX idx_categories_is_active ON categories(is_active);
