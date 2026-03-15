package com.cityvoice.notification.controller;

import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.notification.dto.NotificationResponse;
import com.cityvoice.notification.entity.Notification;
import com.cityvoice.notification.enums.NotificationChannel;
import com.cityvoice.notification.repository.NotificationRepository;
import com.cityvoice.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    /**
     * Lists all in-app notifications for the authenticated citizen, newest first.
     * Email rows are excluded — they are dispatch receipts, not user-facing.
     */
    @GetMapping
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getMyNotifications(
            @AuthenticationPrincipal User citizen) {

        List<NotificationResponse> notifications = notificationRepository
                .findByRecipientIdAndChannelOrderByCreatedAtDesc(citizen.getId(), NotificationChannel.in_app)
                .stream()
                .map(NotificationResponse::fromEntity)
                .toList();

        return ResponseEntity.ok(ApiResponse.success(notifications));
    }

    /**
     * Returns the unread in-app notification count for badge display.
     */
    @GetMapping("/unread-count")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @AuthenticationPrincipal User citizen) {

        long count = notificationRepository.countByRecipientIdAndChannelAndIsReadFalse(
                citizen.getId(), NotificationChannel.in_app);

        return ResponseEntity.ok(ApiResponse.success(Map.of("count", count)));
    }

    /**
     * Marks a single in-app notification as read.
     * Only the owning citizen may mark their own notifications.
     */
    @PutMapping("/{id}/read")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal User citizen) {

        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Thông báo không tồn tại."));

        if (!notification.getRecipient().getId().equals(citizen.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Bạn không có quyền truy cập thông báo này.");
        }

        notification.setRead(true);
        notificationRepository.save(notification);

        return ResponseEntity
                .ok(ApiResponse.success("Đã đánh dấu đã đọc.", NotificationResponse.fromEntity(notification)));
    }
}
