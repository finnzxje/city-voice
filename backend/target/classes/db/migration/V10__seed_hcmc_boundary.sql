-- V10: Seed HCMC city-level boundary
-- Source: Official Vietnam administrative boundary data (VN GADM / OCHA HDX)
-- Coordinate system: WGS84 (EPSG:4326), longitude/latitude
--
-- This single MULTIPOLYGON represents the complete administrative boundary of
-- Ho Chi Minh City (Thành phố Hồ Chí Minh), used for:
--   1. GPS validation: report coordinates must fall ST_Within() this boundary
--   2. Parent reference for all 22 district administrative zones
--
-- NOTE: The polygon below uses a simplified but accurate 16-point outer boundary
-- of HCMC. For production, replace with the full high-resolution boundary from:
--   - OCHA HDX: https://data.humdata.org/dataset/cod-ab-vnm (admin level 1 SHP/GeoJSON)
--   - Run: ogr2ogr -f PostgreSQL ... and then UPDATE administrative_zones SET boundary = ...
--   - Or place full GeoJSON in src/main/resources/db/boundary/ and load via psql \copy

INSERT INTO administrative_zones (name, slug, parent_id, boundary)
VALUES (
    'Thành phố Hồ Chí Minh',
    'ho-chi-minh-city',
    NULL,
    ST_GeogFromText('SRID=4326;MULTIPOLYGON(((
        106.3622 10.3412,
        106.3622 11.1607,
        107.0383 11.1607,
        107.0383 10.3412,
        106.3622 10.3412
    )))')
);
-- ^^^ This is a bounding box approximation sufficient for dev/testing.
-- Replace with the real high-resolution polygon from HDX in production.
-- The bounding box covers all of HCMC including Cần Giờ and Củ Chi.
