-- V1: Enable required PostgreSQL extensions
-- PostGIS for spatial data, uuid-ossp for UUID primary keys

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
