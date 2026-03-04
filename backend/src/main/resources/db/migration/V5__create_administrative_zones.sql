-- V5: Administrative zones table
-- Stores the city-level boundary AND each district boundary for HCMC.
-- Used for:
--   1. GPS validation: citizen's report location must fall within HCMC city boundary
--   2. Zone assignment: report is auto-assigned to the matching district on insert
--   3. Filtering: manager analytics can filter reports by district
--   4. Heatmap: spatial aggregation per zone

CREATE TABLE administrative_zones (
    id          SERIAL      PRIMARY KEY,
    -- Display name: "Thành phố Hồ Chí Minh", "Quận 1", "Thành phố Thủ Đức", etc.
    name        VARCHAR(255) NOT NULL,
    -- URL-safe identifier: "ho-chi-minh-city", "quan-1", "thu-duc"
    slug        VARCHAR(100) UNIQUE NOT NULL,
    -- Parent zone (NULL for the top-level city boundary)
    -- Districts reference the city row, sub-wards would reference districts
    parent_id   INTEGER REFERENCES administrative_zones(id),
    -- PostGIS geography polygon in WGS84 (EPSG:4326)
    boundary    GEOGRAPHY(MULTIPOLYGON, 4326) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Spatial index — critical for ST_Contains() boundary checks and heatmap aggregation
CREATE INDEX idx_admin_zones_boundary  ON administrative_zones USING GIST(boundary);
CREATE INDEX idx_admin_zones_parent_id ON administrative_zones(parent_id);
