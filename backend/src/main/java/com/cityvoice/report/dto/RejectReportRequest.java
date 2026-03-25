package com.cityvoice.report.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RejectReportRequest {

    @NotBlank(message = "Lý do từ chối không được để trống.")
    private String note;
}
