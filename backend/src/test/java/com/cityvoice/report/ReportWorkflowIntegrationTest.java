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
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
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
        User citizen = newCitizen("TC-01");
        Category category = categoryRepository.findAllByIsActiveTrue().stream()
                .findFirst()
                .orElseThrow();

        SubmitReportRequest request = submissionRequest(category.getId(), 10.7769, 106.7009);
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

    @Test
    void tc04_coordinatesOutsideHcmcAreRejectedBeforeStorageUpload() {
        User citizen = newCitizen("TC-04");
        Category category = categoryRepository.findAllByIsActiveTrue().stream()
                .findFirst()
                .orElseThrow();
        long reportCount = reportRepository.count();

        SubmitReportRequest request = submissionRequest(category.getId(), 21.0278, 105.8342);

        assertThatThrownBy(() -> reportService.submitReport(request, citizen))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        exception -> assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        assertThat(reportRepository.count()).isEqualTo(reportCount);
        verifyNoInteractions(storageService);
    }

    @Test
    void tc05_unknownCategoryIsRejectedBeforeStorageUpload() {
        User citizen = newCitizen("TC-05");
        long reportCount = reportRepository.count();

        SubmitReportRequest request = submissionRequest(Integer.MAX_VALUE, 10.7769, 106.7009);

        assertThatThrownBy(() -> reportService.submitReport(request, citizen))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        exception -> assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        assertThat(reportRepository.count()).isEqualTo(reportCount);
        verifyNoInteractions(storageService);
    }

    @Test
    void tc07_citizenOnlySeesTheirOwnReports() {
        User citizen = newCitizen("TC-07 Owner");
        User otherCitizen = newCitizen("TC-07 Other");
        ReportResponse ownReport = submitValidReport(citizen, "tc07-owner.jpg");
        ReportResponse otherReport = submitValidReport(otherCitizen, "tc07-other.jpg");

        List<ReportResponse> visibleReports = reportService.getMyReports(citizen);

        assertThat(visibleReports)
                .extracting(ReportResponse::getId)
                .contains(ownReport.getId())
                .doesNotContain(otherReport.getId());
    }

    @Test
    void tc08_citizenCannotViewAnotherCitizensReport() {
        User citizen = newCitizen("TC-08 Viewer");
        User otherCitizen = newCitizen("TC-08 Owner");
        ReportResponse otherReport = submitValidReport(otherCitizen, "tc08-other.jpg");

        assertThatThrownBy(() -> reportService.getReportById(otherReport.getId(), citizen))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        exception -> assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));
    }

    private User newCitizen(String caseId) {
        return userRepository.save(User.builder()
                .email(caseId.toLowerCase() + "-" + UUID.randomUUID() + "@cityvoice.vn")
                .fullName(caseId + " Citizen")
                .role(UserRole.citizen)
                .active(true)
                .build());
    }

    private SubmitReportRequest submissionRequest(Integer categoryId, double latitude, double longitude) {
        SubmitReportRequest request = new SubmitReportRequest();
        request.setTitle("Pothole on Nguyen Hue Boulevard");
        request.setDescription("Large pothole causing traffic disruption near Quan 1");
        request.setCategoryId(categoryId);
        request.setLatitude(latitude);
        request.setLongitude(longitude);
        request.setImage(TestImages.jpeg("image"));
        return request;
    }

    private ReportResponse submitValidReport(User citizen, String imageFileName) {
        Category category = categoryRepository.findAllByIsActiveTrue().stream()
                .findFirst()
                .orElseThrow();
        when(storageService.store(any(), eq("incidents")))
                .thenReturn("http://storage.test/cityvoice-reports/incidents/" + imageFileName);
        return reportService.submitReport(submissionRequest(category.getId(), 10.7769, 106.7009), citizen);
    }
}
