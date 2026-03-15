package com.cityvoice.report.dto;

import com.cityvoice.report.enums.PriorityLevel;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class ReviewReportRequest {

    @NotNull(message = "Priority is required")
    private PriorityLevel priority;

    @NotNull(message = "Assigned user is required")
    private UUID assignedTo;

    private String note;
}
