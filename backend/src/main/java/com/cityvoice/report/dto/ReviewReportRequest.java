package com.cityvoice.report.dto;

import com.cityvoice.report.enums.PriorityLevel;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class ReviewReportRequest {

    @NotNull(message = "Mức độ ưu tiên không được để trống.")
    private PriorityLevel priority;

    @NotNull(message = "Người được giao không được để trống.")
    private UUID assignedTo;

    private String note;
}
