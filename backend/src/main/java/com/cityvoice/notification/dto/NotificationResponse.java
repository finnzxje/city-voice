package com.cityvoice.notification.dto;

import com.cityvoice.notification.entity.Notification;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class NotificationResponse {

    private UUID id;
    private String type;
    private String message;
    private boolean isRead;
    private OffsetDateTime sentAt;
    private OffsetDateTime createdAt;

    /** The related report ID, may be null for system-wide notifications. */
    private UUID reportId;

    public static NotificationResponse fromEntity(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .type(n.getType())
                .message(n.getMessage())
                .isRead(n.isRead())
                .sentAt(n.getSentAt())
                .createdAt(n.getCreatedAt())
                .reportId(n.getReport() != null ? n.getReport().getId() : null)
                .build();
    }
}
