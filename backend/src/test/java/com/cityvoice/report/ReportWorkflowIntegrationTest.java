package com.cityvoice.report;

import com.cityvoice.report.dto.ReportResponse;
import com.cityvoice.report.dto.SubmitReportRequest;
import com.cityvoice.report.entity.Category;
import com.cityvoice.report.entity.Report;
import com.cityvoice.report.entity.StatusHistory;
import com.cityvoice.report.enums.PriorityLevel;
import com.cityvoice.report.enums.ReportStatus;
import com.cityvoice.report.repository.CategoryRepository;
import com.cityvoice.report.repository.ReportRepository;
import com.cityvoice.report.repository.StatusHistoryRepository;
import com.cityvoice.report.service.ReportService;
import com.cityvoice.storage.StorageService;
import com.cityvoice.testsupport.TestImages;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class ReportWorkflowIntegrationTest {

    @Autowired
    private ReportService reportService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private CategoryRepository categoryRepository;
    @Autowired
    private ReportRepository reportRepository;
    @Autowired
    private StatusHistoryRepository statusHistoryRepository;

    @MockitoBean
    private StorageService storageService;

    @Test
    void tc01_validCitizenReportCreatesNewlyReceivedMediumPriorityReportAndInitialHistory() {
        User citizen = userRepository.save(User.builder()
                .email("tc01-" + UUID.randomUUID() + "@cityvoice.vn")
                .fullName("TC-01 Citizen")
                .role(UserRole.citizen)
                .active(true)
                .build());
        Category category = categoryRepository.findAllByIsActiveTrue().stream()
                .findFirst()
                .orElseThrow();

        SubmitReportRequest request = new SubmitReportRequest();
        request.setTitle("Pothole on Nguyen Hue Boulevard");
        request.setDescription("Large pothole causing traffic disruption near Quan 1");
        request.setCategoryId(category.getId());
        request.setLatitude(10.7769);
        request.setLongitude(106.7009);
        request.setImage(TestImages.jpeg("image"));
        when(storageService.store(any(), eq("incidents")))
                .thenReturn("http://storage.test/cityvoice-reports/incidents/tc01.jpg");

        ReportResponse response = reportService.submitReport(request, citizen);

        assertThat(response.getCurrentStatus()).isEqualTo(ReportStatus.newly_received.name());
        assertThat(response.getPriority()).isEqualTo(PriorityLevel.medium.name());
        assertThat(response.getAdministrativeZoneName()).isEqualTo("Quận 1");
        assertThat(response.getIncidentImageUrl())
                .isEqualTo("http://storage.test/cityvoice-reports/incidents/tc01.jpg");

        Report savedReport = reportRepository.findById(response.getId()).orElseThrow();
        assertThat(savedReport.getCitizen().getId()).isEqualTo(citizen.getId());
        assertThat(savedReport.getCategory().getId()).isEqualTo(category.getId());
        assertThat(savedReport.getCurrentStatus()).isEqualTo(ReportStatus.newly_received);
        assertThat(savedReport.getPriority()).isEqualTo(PriorityLevel.medium);
        assertThat(savedReport.getLocation().getY()).isEqualTo(10.7769);
        assertThat(savedReport.getLocation().getX()).isEqualTo(106.7009);

        List<StatusHistory> histories = statusHistoryRepository.findAll().stream()
                .filter(history -> history.getReport().getId().equals(savedReport.getId()))
                .toList();
        assertThat(histories).singleElement().satisfies(history -> {
            assertThat(history.getChangedBy().getId()).isEqualTo(citizen.getId());
            assertThat(history.getFromStatus()).isNull();
            assertThat(history.getToStatus()).isEqualTo(ReportStatus.newly_received);
        });
        verify(storageService).store(request.getImage(), "incidents");
    }
}
