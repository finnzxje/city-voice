package com.cityvoice.report;

import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.report.controller.CategoryController;
import com.cityvoice.report.dto.CategoryRequest;
import com.cityvoice.report.dto.CategoryResponse;
import com.cityvoice.report.repository.CategoryRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class CategoryIntegrationTest {

    @Autowired
    private CategoryController categoryController;
    @Autowired
    private CategoryRepository categoryRepository;

    @BeforeEach
    void authenticateAdmin() {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "admin",
                "n/a",
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
    }

    @AfterEach
    void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void tc23_adminCreatesActiveCategory() {
        CategoryRequest request = categoryRequest("TC-23 Category", uniqueSlug("tc23"), true);

        ResponseEntity<ApiResponse<CategoryResponse>> response = categoryController.createCategory(request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        CategoryResponse created = response.getBody().getData();
        assertThat(created.getId()).isNotNull();
        assertThat(created.getSlug()).isEqualTo(request.getSlug());
        assertThat(created.isActive()).isTrue();
        assertThat(categoryRepository.findById(created.getId())).isPresent();
    }

    @Test
    void tc24_adminCannotCreateDuplicateCategorySlug() {
        String slug = uniqueSlug("tc24");
        categoryController.createCategory(categoryRequest("TC-24 Original", slug, true));

        assertThatThrownBy(() -> categoryController.createCategory(
                categoryRequest("TC-24 Duplicate", slug, true)))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        exception -> assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
    }

    @Test
    void tc25_inactiveCategoryIsHiddenFromCitizenCategoryList() {
        ResponseEntity<ApiResponse<CategoryResponse>> active = categoryController.createCategory(
                categoryRequest("TC-25 Active", uniqueSlug("tc25-active"), true));
        ResponseEntity<ApiResponse<CategoryResponse>> inactive = categoryController.createCategory(
                categoryRequest("TC-25 Inactive", uniqueSlug("tc25-inactive"), false));

        List<CategoryResponse> visibleCategories = categoryController.listActiveCategories().getBody().getData();

        assertThat(visibleCategories)
                .extracting(CategoryResponse::getId)
                .contains(active.getBody().getData().getId())
                .doesNotContain(inactive.getBody().getData().getId());
    }

    private CategoryRequest categoryRequest(String name, String slug, boolean active) {
        CategoryRequest request = new CategoryRequest();
        request.setName(name);
        request.setSlug(slug);
        request.setIconKey("test-icon");
        request.setActive(active);
        return request;
    }

    private String uniqueSlug(String prefix) {
        return prefix + "-" + UUID.randomUUID();
    }
}
