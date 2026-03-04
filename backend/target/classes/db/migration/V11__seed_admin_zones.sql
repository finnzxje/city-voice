-- V11: Seed HCMC administrative districts (22 units)
-- Source: Vietnam government administrative decree 2024 (post-merger)
-- All coordinates in WGS84 (EPSG:4326), format: longitude latitude
--
-- Ho Chi Minh City has 22 administrative units (as of 2024):
--   - 16 urban districts (Quận 1, 3, 4, 5, 6, 7, 8, 10, 11, 12, Bình Thạnh,
--     Gò Vấp, Phú Nhuận, Tân Bình, Tân Phú, Bình Tân)
--   - 1 city district (Thủ Đức)
--   - 5 rural districts (huyện): Củ Chi, Hóc Môn, Bình Chánh, Nhà Bè, Cần Giờ
--
-- NOTE: Boundaries below are representative bounding polygons for dev/testing.
-- For production quality, load district boundaries from:
--   - OCHA HDX Vietnam admin level 2 dataset
--   - OpenStreetMap Overpass API export for HCMC districts
-- Then run: UPDATE administrative_zones SET boundary = ST_GeogFromText(...) WHERE slug = '...'

-- Get parent city ID for FK reference
DO $$
DECLARE
    city_id INTEGER;
BEGIN
    SELECT id INTO city_id FROM administrative_zones WHERE slug = 'ho-chi-minh-city';

    -- Urban Districts
    INSERT INTO administrative_zones (name, slug, parent_id, boundary) VALUES
    ('Quận 1',      'quan-1',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6850 10.7650, 106.6850 10.7900, 106.7100 10.7900, 106.7100 10.7650, 106.6850 10.7650)))')),
    ('Quận 3',      'quan-3',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6750 10.7750, 106.6750 10.8000, 106.7000 10.8000, 106.7000 10.7750, 106.6750 10.7750)))')),
    ('Quận 4',      'quan-4',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6900 10.7450, 106.6900 10.7700, 106.7100 10.7700, 106.7100 10.7450, 106.6900 10.7450)))')),
    ('Quận 5',      'quan-5',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6500 10.7500, 106.6500 10.7800, 106.6800 10.7800, 106.6800 10.7500, 106.6500 10.7500)))')),
    ('Quận 6',      'quan-6',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6200 10.7400, 106.6200 10.7750, 106.6550 10.7750, 106.6550 10.7400, 106.6200 10.7400)))')),
    ('Quận 7',      'quan-7',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6900 10.7100, 106.6900 10.7500, 106.7350 10.7500, 106.7350 10.7100, 106.6900 10.7100)))')),
    ('Quận 8',      'quan-8',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6200 10.7200, 106.6200 10.7550, 106.6800 10.7550, 106.6800 10.7200, 106.6200 10.7200)))')),
    ('Quận 10',     'quan-10',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6550 10.7700, 106.6550 10.7950, 106.6800 10.7950, 106.6800 10.7700, 106.6550 10.7700)))')),
    ('Quận 11',     'quan-11',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6300 10.7600, 106.6300 10.7900, 106.6600 10.7900, 106.6600 10.7600, 106.6300 10.7600)))')),
    ('Quận 12',     'quan-12',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6350 10.8300, 106.6350 10.8800, 106.6900 10.8800, 106.6900 10.8300, 106.6350 10.8300)))')),
    ('Bình Thạnh',  'binh-thanh',  city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.7000 10.7900, 106.7000 10.8300, 106.7400 10.8300, 106.7400 10.7900, 106.7000 10.7900)))')),
    ('Gò Vấp',      'go-vap',      city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6500 10.8200, 106.6500 10.8600, 106.6950 10.8600, 106.6950 10.8200, 106.6500 10.8200)))')),
    ('Phú Nhuận',   'phu-nhuan',   city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6800 10.7950, 106.6800 10.8150, 106.7050 10.8150, 106.7050 10.7950, 106.6800 10.7950)))')),
    ('Tân Bình',    'tan-binh',    city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6350 10.8000, 106.6350 10.8350, 106.6750 10.8350, 106.6750 10.8000, 106.6350 10.8000)))')),
    ('Tân Phú',     'tan-phu',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6000 10.7850, 106.6000 10.8200, 106.6400 10.8200, 106.6400 10.7850, 106.6000 10.7850)))')),
    ('Bình Tân',    'binh-tan',    city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.5800 10.7600, 106.5800 10.8100, 106.6350 10.8100, 106.6350 10.7600, 106.5800 10.7600)))')),

    -- City-level district
    ('Thành phố Thủ Đức', 'thu-duc', city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.7200 10.8000, 106.7200 11.0000, 106.8500 11.0000, 106.8500 10.8000, 106.7200 10.8000)))')),

    -- Rural districts (huyện)
    ('Huyện Củ Chi',    'cu-chi',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.4000 10.9800, 106.4000 11.1700, 106.6700 11.1700, 106.6700 10.9800, 106.4000 10.9800)))')),
    ('Huyện Hóc Môn',   'hoc-mon',    city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.5700 10.8500, 106.5700 10.9900, 106.6700 10.9900, 106.6700 10.8500, 106.5700 10.8500)))')),
    ('Huyện Bình Chánh', 'binh-chanh', city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.4800 10.6300, 106.4800 10.7800, 106.6800 10.7800, 106.6800 10.6300, 106.4800 10.6300)))')),
    ('Huyện Nhà Bè',    'nha-be',     city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6900 10.6000, 106.6900 10.7200, 106.7500 10.7200, 106.7500 10.6000, 106.6900 10.6000)))')),
    ('Huyện Cần Giờ',   'can-gio',    city_id, ST_GeogFromText('SRID=4326;MULTIPOLYGON(((106.6800 10.3400, 106.6800 10.6200, 107.0400 10.6200, 107.0400 10.3400, 106.6800 10.3400)))'));
END $$;
