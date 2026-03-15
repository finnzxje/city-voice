package com.cityvoice.notification.repository;

import com.cityvoice.notification.entity.Notification;
import com.cityvoice.notification.enums.NotificationChannel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    List<Notification> findByRecipientIdAndChannelOrderByCreatedAtDesc(
            UUID recipientId, NotificationChannel channel);

    long countByRecipientIdAndChannelAndIsReadFalse(
            UUID recipientId, NotificationChannel channel);
}
