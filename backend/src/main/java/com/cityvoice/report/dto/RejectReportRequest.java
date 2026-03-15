package com.cityvoice.report.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RejectReportRequest {

    @NotBlank(message = "A rejection note/reason is required")
    private String note;
}
