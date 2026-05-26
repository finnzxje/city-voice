package com.cityvoice.analytics;

import com.cityvoice.analytics.dto.AnalyticsFilterRequest;
import com.cityvoice.analytics.service.AnalyticsService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles("test")
class AnalyticsIntegrationTest {

    @Autowired
    private AnalyticsService analyticsService;

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
}
