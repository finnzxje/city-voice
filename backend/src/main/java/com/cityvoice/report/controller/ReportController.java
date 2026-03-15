package com.cityvoice.report.controller;

import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.report.dto.RejectReportRequest;
import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.ReviewReportRequest;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.enums.PriorityLevel;
import com.cityvoice.report.enums.ReportStatus;
import com.cityvoice.report.service.ReportService;
import com.cityvoice.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    // ──────────────────────────────────────────────────────────────────────────
    // Citizen endpoints
    // ──────────────────────────────────────────────────────────────────────────

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<ReportResponse>> submitReport(
            @Valid @ModelAttribute SubmitReportRequest request,
            @AuthenticationPrincipal User citizen) {
        log.info("Citizen {} submitting report: {}", citizen.getId(), request);

        ReportResponse response = reportService.submitReport(request, citizen);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Báo cáo đã được gửi thành công.", response));
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<List<ReportResponse>>> getMyReports(
            @AuthenticationPrincipal User citizen) {

        return ResponseEntity.ok(ApiResponse.success(reportService.getMyReports(citizen)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('CITIZEN') or hasRole('STAFF') or hasRole('MANAGER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ReportResponse>> getReportById(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {

        return ResponseEntity.ok(ApiResponse.success(reportService.getReportById(id, user)));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Staff / Manager / Admin endpoints
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Paginated list of all reports with optional filters.
     * Query params: status, priority, assignedTo (UUID), categoryId, page, size,
     * sort.
     */
    @GetMapping
    @PreAuthorize("hasRole('STAFF') or hasRole('MANAGER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Page<ReportResponse>>> getAllReports(
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) PriorityLevel priority,
            @RequestParam(required = false) UUID assignedTo,
            @RequestParam(required = false) Integer categoryId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable,
            @AuthenticationPrincipal User user) {

        Page<ReportResponse> page = reportService.getAllReports(status, priority, assignedTo, categoryId, pageable);
        return ResponseEntity.ok(ApiResponse.success(page));
    }

    /**
     * Review a newly_received report → in_progress.
     * Body: { priority, assignedTo, note? }
     */
    @PutMapping("/{id}/review")
    @PreAuthorize("hasRole('STAFF') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ReportResponse>> reviewReport(
            @PathVariable UUID id,
            @Valid @RequestBody ReviewReportRequest request,
            @AuthenticationPrincipal User staff) {

        ReportResponse response = reportService.reviewReport(id, request, staff);
        return ResponseEntity
                .ok(ApiResponse.success("Báo cáo đã được duyệt và chuyển sang trạng thái xử lý.", response));
    }

    /**
     * Reject a newly_received report (inauthentic).
     * Body: { note }
     */
    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('STAFF') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ReportResponse>> rejectReport(
            @PathVariable UUID id,
            @Valid @RequestBody RejectReportRequest request,
            @AuthenticationPrincipal User staff) {

        ReportResponse response = reportService.rejectReport(id, request, staff);
        return ResponseEntity.ok(ApiResponse.success("Báo cáo đã bị từ chối.", response));
    }

    /**
     * Resolve an in_progress report by uploading proof-of-completion image.
     * Multipart: image (required), note (optional text part).
     */
    @PostMapping(value = "/{id}/resolve", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('STAFF') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ReportResponse>> resolveReport(
            @PathVariable UUID id,
            @RequestPart("image") MultipartFile proofImage,
            @RequestPart(value = "note", required = false) String note,
            @AuthenticationPrincipal User staff) {

        ReportResponse response = reportService.resolveReport(id, proofImage, note, staff);
        return ResponseEntity.ok(ApiResponse.success("Báo cáo đã được đánh dấu hoàn thành.", response));
    }
}
