package com.cityvoice.analytics.dto;

public record HeatmapPointDto(
        double latitude,
        double longitude,
        String priority,
        String category) {
}
