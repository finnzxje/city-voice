package com.cityvoice.report.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class SubmitReportRequest {

    @NotBlank(message = "Tiêu đề không được để trống.")
    @Size(max = 500, message = "Tiêu đề không được vượt quá 500 ký tự.")
    private String title;

    private String description;

    @NotNull(message = "Danh mục không được để trống.")
    private Integer categoryId;

    @NotNull(message = "Vĩ độ không được để trống.")
    @Min(value = -90, message = "Vĩ độ phải nằm trong khoảng từ -90 đến 90.")
    @Max(value = 90, message = "Vĩ độ phải nằm trong khoảng từ -90 đến 90.")
    private Double latitude;

    @NotNull(message = "Kinh độ không được để trống.")
    @Min(value = -180, message = "Kinh độ phải nằm trong khoảng từ -180 đến 180.")
    @Max(value = 180, message = "Kinh độ phải nằm trong khoảng từ -180 đến 180.")
    private Double longitude;

    @NotNull(message = "Ảnh không được để trống.")
    private MultipartFile image;
}
