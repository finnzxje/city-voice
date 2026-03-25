package com.cityvoice.analytics.controller;

import com.cityvoice.analytics.dto.AnalyticsFilterRequest;
import com.cityvoice.analytics.dto.AnalyticsStatsDto;
import com.cityvoice.analytics.dto.HeatmapPointDto;
import com.cityvoice.analytics.service.AnalyticsService;
import com.cityvoice.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/analytics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('MANAGER') or hasRole('ADMIN')")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    /**
     * Returns geo-coordinates for all matching reports.
     * Intended for front-end heatmap rendering (Leaflet.heat, etc.)
     *
     * Query params: from, to, categoryId, zoneId, priority
     */
    @GetMapping("/heatmap")
    public ResponseEntity<ApiResponse<List<HeatmapPointDto>>> heatmap(
            @ModelAttribute AnalyticsFilterRequest filter) {

        log.info("Heatmap request with filter: {}", filter);
        List<HeatmapPointDto> points = analyticsService.getHeatmapData(filter);
        return ResponseEntity.ok(ApiResponse.success("Dữ liệu bản đồ nhiệt.", points));
    }

    /**
     * Returns aggregated statistics for the given filter window.
     *
     * Query params: from, to, categoryId, zoneId, priority
     */
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AnalyticsStatsDto>> stats(
            @ModelAttribute AnalyticsFilterRequest filter) {

        log.info("Stats request with filter: {}", filter);
        AnalyticsStatsDto stats = analyticsService.getStats(filter);
        return ResponseEntity.ok(ApiResponse.success("Thống kê báo cáo.", stats));
    }

    /**
     * Downloads an Excel spreadsheet of all matching incident reports.
     *
     * Query params: from, to, categoryId, zoneId, priority
     */
    @GetMapping("/export/excel")
    public ResponseEntity<byte[]> exportExcel(
            @ModelAttribute AnalyticsFilterRequest filter) {

        log.info("Excel export request with filter: {}", filter);
        byte[] data = analyticsService.exportExcel(filter);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename("cityvoice-reports.xlsx").build().toString())
                .body(data);
    }

    /**
     * Downloads a PDF of all matching incident reports.
     *
     * Query params: from, to, categoryId, zoneId, priority
     */
    @GetMapping("/export/pdf")
    public ResponseEntity<byte[]> exportPdf(
            @ModelAttribute AnalyticsFilterRequest filter) {

        log.info("PDF export request with filter: {}", filter);
        byte[] data = analyticsService.exportPdf(filter);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename("cityvoice-reports.pdf").build().toString())
                .body(data);
    }
}
