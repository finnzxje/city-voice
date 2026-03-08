package com.cityvoice.report.dto;

import com.cityvoice.report.entity.Category;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CategoryResponse {
    private Integer id;
    private String name;
    private String slug;
    private String iconKey;

    public static CategoryResponse fromEntity(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .slug(category.getSlug())
                .iconKey(category.getIconKey())
                .build();
    }
}
