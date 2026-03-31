package com.cityvoice.report.service;

import com.cityvoice.report.dto.CategoryRequest;
import com.cityvoice.report.dto.CategoryResponse;
import com.cityvoice.report.entity.Category;
import com.cityvoice.report.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

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

    @Transactional(readOnly = true)
    public List<CategoryResponse> listAllCategories() {
        return categoryRepository.findAll()
                .stream()
                .map(CategoryResponse::fromEntity)
                .toList();
    }

    @Transactional
    public CategoryResponse createCategory(CategoryRequest request) {
        if (categoryRepository.existsBySlug(request.getSlug())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Slug đã tồn tại: " + request.getSlug());
        }
        Category category = Category.builder()
                .name(request.getName())
                .slug(request.getSlug())
                .iconKey(request.getIconKey())
                .isActive(request.isActive())
                .build();
        return CategoryResponse.fromEntity(categoryRepository.save(category));
    }

    @Transactional
    public CategoryResponse updateCategory(Integer id, CategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy danh mục"));

        // Check slug uniqueness only if slug has changed
        if (!category.getSlug().equals(request.getSlug()) && categoryRepository.existsBySlug(request.getSlug())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Slug đã tồn tại: " + request.getSlug());
        }

        category.setName(request.getName());
        category.setSlug(request.getSlug());
        category.setIconKey(request.getIconKey());
        category.setActive(request.isActive());
        return CategoryResponse.fromEntity(categoryRepository.save(category));
    }
}
