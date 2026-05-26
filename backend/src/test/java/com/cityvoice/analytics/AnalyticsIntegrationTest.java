package com.cityvoice.analytics;

import com.cityvoice.analytics.dto.AnalyticsFilterRequest;
import com.cityvoice.analytics.dto.AnalyticsStatsDto;
import com.cityvoice.analytics.dto.HeatmapPointDto;
import com.cityvoice.analytics.service.AnalyticsService;
import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.entity.Category;
import com.cityvoice.report.enums.PriorityLevel;
import com.cityvoice.report.repository.CategoryRepository;
import com.cityvoice.report.service.ReportService;
import com.cityvoice.storage.StorageService;
import com.cityvoice.testsupport.TestImages;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class AnalyticsIntegrationTest {

    @Autowired
    private AnalyticsService analyticsService;
    @Autowired
    private ReportService reportService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private CategoryRepository categoryRepository;

    @MockitoBean
    private StorageService storageService;

    @Test
    void tc18_managerLoadsAggregateStatsForMatchingReports() {
        Category category = newCategory("TC-18");
        User citizen = newCitizen("TC-18");
        submitReport(category, citizen, "tc18-first.jpg", 10.7769, 106.7009);
        submitReport(category, citizen, "tc18-second.jpg", 10.7769, 106.7009);

        AnalyticsStatsDto stats = analyticsService.getStats(filterByCategory(category));

        assertThat(stats.totalReports()).isEqualTo(2);
        assertThat(stats.newlyReceived()).isEqualTo(2);
        assertThat(stats.inProgress()).isZero();
        assertThat(stats.resolved()).isZero();
        assertThat(stats.byCategory()).containsEntry(category.getName(), 2L);
        assertThat(stats.byPriority()).containsEntry(PriorityLevel.medium.name(), 2L);
    }

    @Test
    void tc19_managerLoadsHeatmapCoordinatesForMatchingReports() {
        Category category = newCategory("TC-19");
        User citizen = newCitizen("TC-19");
        submitReport(category, citizen, "tc19.jpg", 10.7769, 106.7009);

        List<HeatmapPointDto> points = analyticsService.getHeatmapData(filterByCategory(category));

        assertThat(points).singleElement().satisfies(point -> {
            assertThat(point.latitude()).isEqualTo(10.7769);
            assertThat(point.longitude()).isEqualTo(106.7009);
            assertThat(point.priority()).isEqualTo(PriorityLevel.medium.name());
            assertThat(point.category()).isEqualTo(category.getName());
        });
    }

    @Test
    void tc20_invalidDateRangeIsRejected() {
        AnalyticsFilterRequest filter = new AnalyticsFilterRequest(
                LocalDate.of(2026, 5, 27),
                LocalDate.of(2026, 5, 1),
                null,
                null,
                null);

        assertThatThrownBy(() -> analyticsService.getStats(filter))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        exception -> assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    private Category newCategory(String caseId) {
        return categoryRepository.save(Category.builder()
                .name(caseId + " Category")
                .slug(caseId.toLowerCase() + "-" + UUID.randomUUID())
                .isActive(true)
                .build());
    }

    private User newCitizen(String caseId) {
        return userRepository.save(User.builder()
                .email(caseId.toLowerCase() + "-" + UUID.randomUUID() + "@cityvoice.vn")
                .fullName(caseId + " Citizen")
                .role(UserRole.citizen)
                .active(true)
                .build());
    }

    private ReportResponse submitReport(Category category, User citizen, String imageFileName,
            double latitude, double longitude) {
        SubmitReportRequest request = new SubmitReportRequest();
        request.setTitle("Analytics report");
        request.setDescription("Report created for analytics integration testing");
        request.setCategoryId(category.getId());
        request.setLatitude(latitude);
        request.setLongitude(longitude);
        request.setImage(TestImages.jpeg("image"));
        when(storageService.store(any(), eq("incidents")))
                .thenReturn("http://storage.test/cityvoice-reports/incidents/" + imageFileName);
        return reportService.submitReport(request, citizen);
    }

    private AnalyticsFilterRequest filterByCategory(Category category) {
        return new AnalyticsFilterRequest(null, null, category.getId(), null, null);
    }
}
