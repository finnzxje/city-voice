package com.cityvoice.report.service;

import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.entity.AdministrativeZone;
import com.cityvoice.report.entity.Category;
import com.cityvoice.report.entity.Report;
import com.cityvoice.report.entity.StatusHistory;
import com.cityvoice.report.enums.ReportStatus;
import com.cityvoice.report.repository.AdministrativeZoneRepository;
import com.cityvoice.report.repository.CategoryRepository;
import com.cityvoice.report.repository.ReportRepository;
import com.cityvoice.report.repository.StatusHistoryRepository;
import com.cityvoice.storage.StorageService;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReportService {

    private final ReportRepository reportRepository;
    private final CategoryRepository categoryRepository;
    private final AdministrativeZoneRepository zoneRepository;
    private final StatusHistoryRepository statusHistoryRepository;
    private final StorageService storageService;

    // Factory initialized with SRID 4326 (WGS84)
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public ReportResponse submitReport(SubmitReportRequest request, User citizen) {
        log.info("Citizen {} submitting report: lat={}, lon={}", citizen.getId(), request.getLatitude(),
                request.getLongitude());

        // 1. Verify category exists and is active
        Category category = categoryRepository.findById(request.getCategoryId())
                .filter(Category::isActive)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or inactive category"));

        // 2. ST_Contains against overall HCMC boundary
        boolean isInsideCity = zoneRepository.isWithinCityBoundary(request.getLongitude(), request.getLatitude());
        if (!isInsideCity) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Incident location is outside Ho Chi Minh City bounds");
        }

        // 3. Find matching district (can be null if inside city bbox but outside
        // specific district polygon)
        AdministrativeZone district = zoneRepository
                .findDistrictByCoordinate(request.getLongitude(), request.getLatitude())
                .orElse(null);

        // 4. Create JTS Point
        Point point = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));

        // 5. Store image in MinIO
        String imageUrl = storageService.store(request.getImage(), "incidents");

        // 6. Persist Report
        Report report = Report.builder()
                .citizen(citizen)
                .category(category)
                .title(request.getTitle())
                .description(request.getDescription())
                .location(point)
                .administrativeZone(district)
                .incidentImageUrl(imageUrl)
                .currentStatus(ReportStatus.newly_received)
                .build();

        report = reportRepository.save(report);

        // 7. Persist initial Status History
        StatusHistory history = StatusHistory.builder()
                .report(report)
                .changedBy(citizen) // The citizen who reported it initiated the status
                .fromStatus(null) // No previous status
                .toStatus(ReportStatus.newly_received)
                .build();

        statusHistoryRepository.save(history);

        return ReportResponse.fromEntity(report);
    }

    @Transactional(readOnly = true)
    public List<ReportResponse> getMyReports(User citizen) {
        return reportRepository.findAllByCitizenIdOrderByCreatedAtDesc(citizen.getId())
                .stream()
                .map(ReportResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public ReportResponse getReportById(UUID reportId, User currentContextUser) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Report not found"));

        // Citizens can only view their own reports. Staff/managers/admins can view any.
        if (currentContextUser.getRole() == UserRole.citizen) {
            if (!report.getCitizen().getId().equals(currentContextUser.getId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to this report");
            }
        }

        return ReportResponse.fromEntity(report);
    }
}
