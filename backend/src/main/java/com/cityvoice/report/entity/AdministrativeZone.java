package com.cityvoice.report.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.locationtech.jts.geom.MultiPolygon;

import java.time.OffsetDateTime;

@Entity
@Table(name = "administrative_zones")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdministrativeZone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(name = "parent_id")
    private Integer parentId;

    /**
     * PostGIS GEOGRAPHY(MULTIPOLYGON, 4326) column.
     * Hibernate Spatial maps this to/from JTS MultiPolygon automatically.
     */
    @Column(columnDefinition = "geography(MultiPolygon,4326)", nullable = false)
    private MultiPolygon boundary;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}
