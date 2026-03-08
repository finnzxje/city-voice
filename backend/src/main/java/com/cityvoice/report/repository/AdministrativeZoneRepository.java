package com.cityvoice.report.repository;

import com.cityvoice.report.entity.AdministrativeZone;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AdministrativeZoneRepository extends JpaRepository<AdministrativeZone, Integer> {

    /**
     * Finds the district (parent_id IS NOT NULL) that contains the given
     * coordinate.
     * Uses PostGIS ST_Contains and ST_MakePoint.
     * Note: Geography points require explicit casting to geometry in some PostGIS
     * functions.
     *
     * @param lon Longitude (X coordinate)
     * @param lat Latitude (Y coordinate)
     * @return The containing district, if any
     */
    @Query(value = """
            SELECT * FROM administrative_zones
            WHERE parent_id IS NOT NULL
              AND ST_Contains(boundary::geometry, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
            LIMIT 1
            """, nativeQuery = true)
    Optional<AdministrativeZone> findDistrictByCoordinate(@Param("lon") double lon, @Param("lat") double lat);

    /**
     * Checks if a point lies within the overall city boundary (parent_id IS NULL).
     */
    @Query(value = """
            SELECT COUNT(*) > 0 FROM administrative_zones
            WHERE parent_id IS NULL
              AND ST_Contains(boundary::geometry, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
            """, nativeQuery = true)
    boolean isWithinCityBoundary(@Param("lon") double lon, @Param("lat") double lat);
}
