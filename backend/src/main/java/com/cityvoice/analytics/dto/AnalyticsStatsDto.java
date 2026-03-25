package com.cityvoice.analytics.dto;

import java.util.Map;

public record AnalyticsStatsDto(
        long totalReports,
        long newlyReceived,
        long inProgress,
        long resolved,
        long rejected,
        double completionRate,
        Double averageResolutionHours,
        Map<String, Long> byCategory,
        Map<String, Long> byPriority,
        Map<String, Long> byZone) {
}
