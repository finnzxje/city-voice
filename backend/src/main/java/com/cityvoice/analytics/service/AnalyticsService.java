package com.cityvoice.analytics.service;

import com.cityvoice.analytics.dto.AnalyticsFilterRequest;
import com.cityvoice.analytics.dto.AnalyticsStatsDto;
import com.cityvoice.analytics.dto.HeatmapPointDto;
import com.cityvoice.report.entity.Report;
import com.cityvoice.report.enums.ReportStatus;
import com.cityvoice.report.repository.ReportRepository;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final ReportRepository reportRepository;

    // ──────────────────────────────────────────────────────────────────────────
    // Core helpers
    // ──────────────────────────────────────────────────────────────────────────

    private Specification<Report> buildSpec(AnalyticsFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (filter.from() != null) {
                predicates.add(cb.greaterThanOrEqualTo(
                        root.get("createdAt"),
                        filter.from().atStartOfDay().atOffset(ZoneOffset.UTC)));
            }
            if (filter.to() != null) {
                predicates.add(cb.lessThan(
                        root.get("createdAt"),
                        filter.to().plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC)));
            }
            if (filter.categoryId() != null) {
                predicates.add(cb.equal(root.get("category").get("id"), filter.categoryId()));
            }
            if (filter.zoneId() != null) {
                predicates.add(cb.equal(root.get("administrativeZone").get("id"), filter.zoneId()));
            }
            if (filter.priority() != null) {
                predicates.add(cb.equal(root.get("priority"), filter.priority()));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    private List<Report> fetchFiltered(AnalyticsFilterRequest filter) {
        return reportRepository.findAll(buildSpec(filter));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Heatmap
    // ──────────────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<HeatmapPointDto> getHeatmapData(AnalyticsFilterRequest filter) {
        return fetchFiltered(filter).stream()
                .filter(r -> r.getLocation() != null)
                .map(r -> new HeatmapPointDto(
                        r.getLocation().getY(), // latitude = Y
                        r.getLocation().getX(), // longitude = X
                        r.getPriority() != null ? r.getPriority().name() : null,
                        r.getCategory() != null ? r.getCategory().getName() : null))
                .toList();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Stats
    // ──────────────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public AnalyticsStatsDto getStats(AnalyticsFilterRequest filter) {
        List<Report> reports = fetchFiltered(filter);

        long total = reports.size();
        long newlyReceived = count(reports, ReportStatus.newly_received);
        long inProgress = count(reports, ReportStatus.in_progress);
        long resolved = count(reports, ReportStatus.resolved);
        long rejected = count(reports, ReportStatus.rejected);

        double completionRate = total == 0 ? 0.0 : Math.round((double) resolved / total * 10000.0) / 100.0;

        Double avgResolutionHours = computeAvgResolutionHours(reports);

        Map<String, Long> byCategory = reports.stream()
                .filter(r -> r.getCategory() != null)
                .collect(Collectors.groupingBy(r -> r.getCategory().getName(), Collectors.counting()));

        Map<String, Long> byPriority = reports.stream()
                .filter(r -> r.getPriority() != null)
                .collect(Collectors.groupingBy(r -> r.getPriority().name(), Collectors.counting()));

        Map<String, Long> byZone = reports.stream()
                .filter(r -> r.getAdministrativeZone() != null)
                .collect(Collectors.groupingBy(r -> r.getAdministrativeZone().getName(), Collectors.counting()));

        return new AnalyticsStatsDto(
                total, newlyReceived, inProgress, resolved, rejected,
                completionRate, avgResolutionHours,
                byCategory, byPriority, byZone);
    }

    private long count(List<Report> reports, ReportStatus status) {
        return reports.stream().filter(r -> r.getCurrentStatus() == status).count();
    }

    private Double computeAvgResolutionHours(List<Report> reports) {
        List<Long> hours = reports.stream()
                .filter(r -> r.getCurrentStatus() == ReportStatus.resolved
                        && r.getResolvedAt() != null
                        && r.getCreatedAt() != null)
                .map(r -> Duration.between(r.getCreatedAt(), r.getResolvedAt()).toHours())
                .toList();
        return hours.isEmpty() ? null : hours.stream().mapToLong(Long::longValue).average().orElse(0);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Excel export
    // ──────────────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public byte[] exportExcel(AnalyticsFilterRequest filter) {
        List<Report> reports = fetchFiltered(filter);

        try (Workbook workbook = new XSSFWorkbook();
                ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            Sheet sheet = workbook.createSheet("Incident Reports");

            // Header style
            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setColor(IndexedColors.WHITE.getIndex());
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);

            // Header row
            String[] headers = { "ID", "Title", "Category", "Priority", "Status",
                    "Zone", "Citizen", "Assigned To", "Created At", "Resolved At" };
            org.apache.poi.ss.usermodel.Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
                sheet.setColumnWidth(i, 5000);
            }

            // Data rows
            int rowIdx = 1;
            for (Report r : reports) {
                org.apache.poi.ss.usermodel.Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(r.getId().toString());
                row.createCell(1).setCellValue(r.getTitle());
                row.createCell(2).setCellValue(r.getCategory() != null ? r.getCategory().getName() : "");
                row.createCell(3).setCellValue(r.getPriority() != null ? r.getPriority().name() : "");
                row.createCell(4).setCellValue(r.getCurrentStatus().name());
                row.createCell(5)
                        .setCellValue(r.getAdministrativeZone() != null ? r.getAdministrativeZone().getName() : "");
                row.createCell(6).setCellValue(r.getCitizen() != null ? r.getCitizen().getEmail() : "");
                row.createCell(7).setCellValue(r.getAssignedTo() != null ? r.getAssignedTo().getEmail() : "");
                row.createCell(8).setCellValue(r.getCreatedAt() != null ? r.getCreatedAt().toString() : "");
                row.createCell(9).setCellValue(r.getResolvedAt() != null ? r.getResolvedAt().toString() : "");
            }

            workbook.write(out);
            return out.toByteArray();

        } catch (Exception e) {
            log.error("Failed to generate Excel export", e);
            throw new RuntimeException("Excel export failed", e);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // PDF export
    // ──────────────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public byte[] exportPdf(AnalyticsFilterRequest filter) {
        List<Report> reports = fetchFiltered(filter);

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter.getInstance(document, out);
            document.open();

            // Title
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, Color.WHITE);
            PdfPTable titleTable = new PdfPTable(1);
            titleTable.setWidthPercentage(100);
            PdfPCell titleCell = new PdfPCell(new Phrase("CityVoice Incident Reports", titleFont));
            titleCell.setBackgroundColor(new Color(30, 58, 138)); // dark blue
            titleCell.setPadding(10);
            titleCell.setBorder(Rectangle.NO_BORDER);
            titleTable.addCell(titleCell);
            document.add(titleTable);
            document.add(new Paragraph(" "));

            // Table
            PdfPTable table = new PdfPTable(8);
            table.setWidthPercentage(100);
            table.setWidths(new float[] { 3f, 6f, 3f, 2.5f, 3f, 3.5f, 3.5f, 3.5f });

            String[] cols = { "ID (short)", "Title", "Category", "Priority",
                    "Status", "Zone", "Citizen", "Created At" };

            Font colFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.WHITE);
            Color headerBg = new Color(30, 58, 138);
            for (String col : cols) {
                PdfPCell cell = new PdfPCell(new Phrase(col, colFont));
                cell.setBackgroundColor(headerBg);
                cell.setPadding(5);
                table.addCell(cell);
            }

            Font dataFont = FontFactory.getFont(FontFactory.HELVETICA, 7, Color.BLACK);
            boolean alt = false;
            Color altBg = new Color(239, 246, 255);
            for (Report r : reports) {
                Color rowBg = alt ? altBg : Color.WHITE;
                alt = !alt;

                addPdfCell(table, dataFont, rowBg, r.getId().toString().substring(0, 8) + "…");
                addPdfCell(table, dataFont, rowBg, r.getTitle());
                addPdfCell(table, dataFont, rowBg, r.getCategory() != null ? r.getCategory().getName() : "");
                addPdfCell(table, dataFont, rowBg, r.getPriority() != null ? r.getPriority().name() : "");
                addPdfCell(table, dataFont, rowBg, r.getCurrentStatus().name());
                addPdfCell(table, dataFont, rowBg,
                        r.getAdministrativeZone() != null ? r.getAdministrativeZone().getName() : "");
                addPdfCell(table, dataFont, rowBg, r.getCitizen() != null ? r.getCitizen().getEmail() : "");
                addPdfCell(table, dataFont, rowBg,
                        r.getCreatedAt() != null ? r.getCreatedAt().toLocalDate().toString() : "");
            }

            document.add(table);

            // Footer
            document.add(new Paragraph(" "));
            Font footerFont = FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 8, Color.GRAY);
            document.add(
                    new Paragraph("Generated by CityVoice Analytics  •  Total records: " + reports.size(), footerFont));

            document.close();
            return out.toByteArray();

        } catch (Exception e) {
            log.error("Failed to generate PDF export", e);
            throw new RuntimeException("PDF export failed", e);
        }
    }

    private void addPdfCell(PdfPTable table, Font font, Color bg, String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setBackgroundColor(bg);
        cell.setPadding(4);
        table.addCell(cell);
    }
}
