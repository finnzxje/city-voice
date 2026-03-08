package com.cityvoice.report.controller;

import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.service.ReportService;
import com.cityvoice.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ReportResponse> submitReport(
            @Valid @ModelAttribute SubmitReportRequest request,
            @AuthenticationPrincipal User citizen) {
        log.info("Citizen {} submitting report: {}", citizen.getId(), request);

        ReportResponse response = reportService.submitReport(request, citizen);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<List<ReportResponse>> getMyReports(
            @AuthenticationPrincipal User citizen) {

        return ResponseEntity.ok(reportService.getMyReports(citizen));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('CITIZEN') or hasRole('STAFF') or hasRole('MANAGER') or hasRole('ADMIN')")
    public ResponseEntity<ReportResponse> getReportById(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {

        return ResponseEntity.ok(reportService.getReportById(id, user));
    }
}
