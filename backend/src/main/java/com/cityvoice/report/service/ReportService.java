package com.cityvoice.report.service;

import com.cityvoice.notification.service.NotificationService;
import com.cityvoice.report.dto.RejectReportRequest;
import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.ReviewReportRequest;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.entity.AdministrativeZone;
import com.cityvoice.report.entity.Category;
import com.cityvoice.report.entity.Report;
import com.cityvoice.report.entity.StatusHistory;
import com.cityvoice.report.enums.PriorityLevel;
import com.cityvoice.report.enums.ReportStatus;
import com.cityvoice.report.repository.AdministrativeZoneRepository;
import com.cityvoice.report.repository.CategoryRepository;
import com.cityvoice.report.repository.ReportRepository;
import com.cityvoice.report.repository.ReportSpecification;
import com.cityvoice.report.repository.StatusHistoryRepository;
import com.cityvoice.storage.StorageService;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
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
        private final UserRepository userRepository;
        private final NotificationService notificationService;

        // Factory initialized with SRID 4326 (WGS84)
        private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

        // ──────────────────────────────────────────────────────────────────────────
        // Citizen endpoints
        // ──────────────────────────────────────────────────────────────────────────

        @Transactional
        public ReportResponse submitReport(SubmitReportRequest request, User citizen) {
                log.info("Citizen {} submitting report: lat={}, lon={}", citizen.getId(), request.getLatitude(),
                                request.getLongitude());

                // 1. Verify category exists and is active
                Category category = categoryRepository.findById(request.getCategoryId())
                                .filter(Category::isActive)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                                "Danh mục không hợp lệ hoặc đã ngừng hoạt động."));

                // 2. ST_Contains against overall HCMC boundary
                boolean isInsideCity = zoneRepository.isWithinCityBoundary(request.getLongitude(),
                                request.getLatitude());
                if (!isInsideCity) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "Vị trí sự cố nằm ngoài phạm vi TP. Hồ Chí Minh.");
                }

                // 3. Find matching district (can be null if inside city bbox but outside
                // specific district polygon)
                AdministrativeZone district = zoneRepository
                                .findDistrictByCoordinate(request.getLongitude(), request.getLatitude())
                                .orElse(null);

                // 4. Create JTS Point
                Point point = geometryFactory
                                .createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));

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

                report = reportRepository.saveAndFlush(report);

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
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Báo cáo không tồn tại."));

                // Citizens can only view their own reports. Staff/managers/admins can view any.
                if (currentContextUser.getRole() == UserRole.citizen) {
                        if (!report.getCitizen().getId().equals(currentContextUser.getId())) {
                                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                                "Bạn không có quyền truy cập báo cáo này.");
                        }
                }

                return ReportResponse.fromEntity(report);
        }

        // ──────────────────────────────────────────────────────────────────────────
        // Staff endpoints
        // ──────────────────────────────────────────────────────────────────────────

        /**
         * Staff/manager/admin: paginated list of all reports with optional filters.
         */
        @Transactional(readOnly = true)
        public Page<ReportResponse> getAllReports(
                        ReportStatus status,
                        PriorityLevel priority,
                        UUID assignedToId,
                        Integer categoryId,
                        Pageable pageable) {

                return reportRepository
                                .findAll(ReportSpecification.buildFilter(status, priority, assignedToId, categoryId),
                                                pageable)
                                .map(ReportResponse::fromEntity);
        }

        /**
         * Staff: accept a {@code newly_received} report → {@code in_progress}.
         * Sets priority and assigns to a user.
         */
        @Transactional
        public ReportResponse reviewReport(UUID reportId, ReviewReportRequest request, User staff) {
                Report report = loadReport(reportId);
                assertStatus(report, ReportStatus.newly_received,
                                "Chỉ có thể duyệt báo cáo đang ở trạng thái 'Mới nhận'.");

                User assignee = userRepository.findById(request.getAssignedTo())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                                "Người được giao không tồn tại trong hệ thống."));

                report.setPriority(request.getPriority());
                report.setAssignedTo(assignee);
                report.setCurrentStatus(ReportStatus.in_progress);
                reportRepository.save(report);

                appendHistory(report, staff, ReportStatus.newly_received, ReportStatus.in_progress, request.getNote());

                log.info("Staff {} reviewed report {} → in_progress (priority={}, assignedTo={})",
                                staff.getId(), reportId, request.getPriority(), assignee.getId());
                return ReportResponse.fromEntity(report);
        }

        /**
         * Staff: reject a {@code newly_received} report (inauthentic).
         * Notifies the citizen.
         */
        @Transactional
        public ReportResponse rejectReport(UUID reportId, RejectReportRequest request, User staff) {
                Report report = loadReport(reportId);
                assertStatus(report, ReportStatus.newly_received,
                                "Chỉ có thể từ chối báo cáo đang ở trạng thái 'Mới nhận'.");

                report.setCurrentStatus(ReportStatus.rejected);
                reportRepository.save(report);

                appendHistory(report, staff, ReportStatus.newly_received, ReportStatus.rejected, request.getNote());
                notificationService.notifyRejected(report, staff, request.getNote());

                log.info("Staff {} rejected report {}", staff.getId(), reportId);
                return ReportResponse.fromEntity(report);
        }

        /**
         * Staff: resolve an {@code in_progress} report by uploading proof-of-completion
         * image.
         * Notifies the citizen.
         */
        @Transactional
        public ReportResponse resolveReport(UUID reportId, MultipartFile proofImage, String note, User staff) {
                Report report = loadReport(reportId);
                assertStatus(report, ReportStatus.in_progress,
                                "Chỉ có thể hoàn thành báo cáo đang ở trạng thái 'Đang xử lý'.");
                assertAssignedTo(report, staff);

                String proofUrl = storageService.store(proofImage, "resolutions");
                report.setResolutionImageUrl(proofUrl);
                report.setResolvedAt(OffsetDateTime.now());
                report.setCurrentStatus(ReportStatus.resolved);
                reportRepository.save(report);

                appendHistory(report, staff, ReportStatus.in_progress, ReportStatus.resolved, note);
                notificationService.notifyResolved(report, staff);

                log.info("Staff {} resolved report {}", staff.getId(), reportId);
                return ReportResponse.fromEntity(report);
        }

        // ──────────────────────────────────────────────────────────────────────────
        // Private helpers
        // ──────────────────────────────────────────────────────────────────────────

        private Report loadReport(UUID reportId) {
                return reportRepository.findById(reportId)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Báo cáo không tồn tại."));
        }

        /** Throws 400 if the report's current status is not the expected one. */
        private void assertStatus(Report report, ReportStatus expected, String message) {
                if (report.getCurrentStatus() != expected) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
                }
        }

        /**
         * Throws 403 if the acting staff is not the assigned staff member.
         * Admins are always exempt.
         */
        private void assertAssignedTo(Report report, User actor) {
                if (actor.getRole() == UserRole.admin) return;
                User assignee = report.getAssignedTo();
                if (assignee == null || !assignee.getId().equals(actor.getId())) {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                        "Chỉ nhân viên được giao mới có thể thực hiện thao tác này.");
                }
        }

        private void appendHistory(Report report, User actor,
                        ReportStatus from, ReportStatus to, String note) {
                StatusHistory history = StatusHistory.builder()
                                .report(report)
                                .changedBy(actor)
                                .fromStatus(from)
                                .toStatus(to)
                                .note(note)
                                .build();
                statusHistoryRepository.save(history);
        }
}
