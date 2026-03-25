package com.cityvoice.analytics.dto;

import com.cityvoice.report.enums.PriorityLevel;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

/**
 * Query parameters shared across all analytics endpoints.
 *
 * @param from       inclusive start date (optional)
 * @param to         inclusive end date (optional)
 * @param categoryId filter by category (optional)
 * @param zoneId     filter by administrative zone id (optional)
 * @param priority   filter by priority level (optional)
 */
public record AnalyticsFilterRequest(
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        Integer categoryId,
        Integer zoneId,
        PriorityLevel priority) {
}
