package com.cityvoice.report.service;

import com.cityvoice.report.dto.CategoryResponse;
import com.cityvoice.report.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    @Transactional(readOnly = true)
    public List<CategoryResponse> listActiveCategories() {
        return categoryRepository.findAllByIsActiveTrue()
                .stream()
                .map(CategoryResponse::fromEntity)
                .toList();
    }
}
