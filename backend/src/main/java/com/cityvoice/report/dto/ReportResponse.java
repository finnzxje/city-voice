package com.cityvoice.report.dto;

import com.cityvoice.report.entity.Report;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class ReportResponse {
    private UUID id;
    private String title;
    private String description;
    private Integer categoryId;
    private String categoryName;
    private Double latitude;
    private Double longitude;
    private String administrativeZoneName;
    private String incidentImageUrl;
    private String resolutionImageUrl;
    private String currentStatus;
    private String priority;
    private UUID citizenId;
    private String citizenName;
    private UUID assignedToId;
    private String assignedToName;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private OffsetDateTime resolvedAt;

    public static ReportResponse fromEntity(Report report) {
        return ReportResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .description(report.getDescription())
                .categoryId(report.getCategory().getId())
                .categoryName(report.getCategory().getName())
                // Get coordinates from JTS Point using Y for lat, X for lon
                .latitude(report.getLocation().getY())
                .longitude(report.getLocation().getX())
                .administrativeZoneName(
                        report.getAdministrativeZone() != null ? report.getAdministrativeZone().getName() : null)
                .incidentImageUrl(report.getIncidentImageUrl())
                .resolutionImageUrl(report.getResolutionImageUrl())
                .currentStatus(report.getCurrentStatus().name())
                .priority(report.getPriority() != null ? report.getPriority().name() : null)
                .citizenId(report.getCitizen().getId())
                .citizenName(report.getCitizen().getFullName())
                .assignedToId(report.getAssignedTo() != null ? report.getAssignedTo().getId() : null)
                .assignedToName(report.getAssignedTo() != null ? report.getAssignedTo().getFullName() : null)
                .createdAt(report.getCreatedAt())
                .updatedAt(report.getUpdatedAt())
                .resolvedAt(report.getResolvedAt())
                .build();
    }
}
