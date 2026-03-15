package com.cityvoice.report.controller;

import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.report.dto.CategoryResponse;
import com.cityvoice.report.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> listActiveCategories() {
        return ResponseEntity.ok(ApiResponse.success(categoryService.listActiveCategories()));
    }
}
