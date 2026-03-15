package com.cityvoice.notification.service;

import com.cityvoice.auth.service.EmailService;
import com.cityvoice.notification.entity.Notification;
import com.cityvoice.notification.enums.NotificationChannel;
import com.cityvoice.notification.repository.NotificationRepository;
import com.cityvoice.report.entity.Report;
import com.cityvoice.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final EmailService emailService;

    /**
     * Fires dual-channel (in-app + email) notifications when a report is resolved.
     * The in-app row is persisted with sentAt=now(); the email is dispatched via
     * EmailService.
     * Email rows are audit-only — isRead stays false permanently.
     */
    @Transactional
    public void notifyResolved(Report report, User actor) {
        User citizen = report.getCitizen();
        String title = report.getTitle();
        String type = "report_resolved";
        String message = "Báo cáo \"%s\" của bạn đã được giải quyết thành công.".formatted(title);

        persistInApp(citizen, report, type, message);
        persistEmailReceipt(citizen, report, type, message);

        String htmlBody = buildStatusEmailBody(title, "Đã giải quyết",
                "Chúng tôi vui mừng thông báo rằng báo cáo của bạn đã được xử lý và hoàn tất.");
        try {
            emailService.sendNotificationEmail(citizen.getEmail(),
                    "[CityVoice] Báo cáo của bạn đã được giải quyết", htmlBody);
        } catch (Exception e) {
            log.error("Failed to send resolution email to citizen {}: {}", citizen.getId(), e.getMessage());
        }
    }

    /**
     * Fires dual-channel notifications when a report is rejected.
     */
    @Transactional
    public void notifyRejected(Report report, User actor, String note) {
        User citizen = report.getCitizen();
        String title = report.getTitle();
        String type = "report_rejected";
        String reason = (note != null && !note.isBlank()) ? note : "Không có lý do cụ thể.";
        String message = "Báo cáo \"%s\" của bạn đã bị từ chối. Lý do: %s".formatted(title, reason);

        persistInApp(citizen, report, type, message);
        persistEmailReceipt(citizen, report, type, message);

        String htmlBody = buildStatusEmailBody(title, "Đã từ chối",
                "Rất tiếc, báo cáo của bạn đã bị từ chối với lý do: " + reason);
        try {
            emailService.sendNotificationEmail(citizen.getEmail(),
                    "[CityVoice] Báo cáo của bạn đã bị từ chối", htmlBody);
        } catch (Exception e) {
            log.error("Failed to send rejection email to citizen {}: {}", citizen.getId(), e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    private void persistInApp(User recipient, Report report, String type, String message) {
        Notification n = Notification.builder()
                .recipient(recipient)
                .report(report)
                .type(type)
                .message(message)
                .channel(NotificationChannel.in_app)
                .sentAt(OffsetDateTime.now())
                .build();
        notificationRepository.save(n);
    }

    /**
     * Persists an email row as a dispatch receipt.
     * sentAt is set immediately; isRead stays false permanently (no UI surface for
     * email rows).
     */
    private void persistEmailReceipt(User recipient, Report report, String type, String message) {
        Notification n = Notification.builder()
                .recipient(recipient)
                .report(report)
                .type(type)
                .message(message)
                .channel(NotificationChannel.email)
                .sentAt(OffsetDateTime.now())
                .build();
        notificationRepository.save(n);
    }

    private String buildStatusEmailBody(String reportTitle, String statusLabel, String detail) {
        return """
                <div style="font-family: Arial, sans-serif; max-width: 520px; margin: auto; padding: 32px; border: 1px solid #e0e0e0; border-radius: 8px;">
                  <h2 style="color: #1a73e8;">CityVoice – Cập nhật báo cáo</h2>
                  <p>Báo cáo: <strong>%s</strong></p>
                  <p>Trạng thái mới: <strong style="color: #333;">%s</strong></p>
                  <p>%s</p>
                  <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
                  <p style="color: #999; font-size: 12px;">CityVoice – Hệ thống báo cáo sự cố đô thị tại TP. Hồ Chí Minh</p>
                </div>
                """
                .formatted(reportTitle, statusLabel, detail);
    }
}
