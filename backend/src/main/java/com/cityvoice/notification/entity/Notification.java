package com.cityvoice.notification.entity;

import com.cityvoice.notification.enums.NotificationChannel;
import com.cityvoice.report.entity.Report;
import com.cityvoice.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** The user who receives this notification. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User recipient;

    /**
     * The report this notification relates to (nullable for system-wide
     * notifications).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id")
    private Report report;

    /**
     * Notification type identifier for frontend rendering.
     * e.g. "report_resolved", "report_rejected"
     */
    @Column(nullable = false, length = 100)
    private String type;

    /** Pre-rendered message body (plain text or HTML for email). */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /** Delivery channel. */
    @Column(nullable = false, columnDefinition = "notification_channel")
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Enumerated(EnumType.STRING)
    private NotificationChannel channel;

    /**
     * In-app read status.
     * Only meaningful for {@code in_app} channel rows.
     * Email rows remain {@code false} permanently.
     */
    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private boolean isRead = false;

    /**
     * Dispatch timestamp.
     * {@code null} = queued/pending; set to NOW() when successfully sent.
     */
    @Column(name = "sent_at")
    private OffsetDateTime sentAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}
