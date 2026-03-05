package com.cityvoice.user.repository;

import com.cityvoice.user.entity.OtpToken;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.OtpType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpTokenRepository extends JpaRepository<OtpToken, UUID> {

    Optional<OtpToken> findByTokenAndUserAndTypeAndUsedAtIsNullAndExpiresAtAfter(
            String token, User user, OtpType type, OffsetDateTime now);

    // Invalidate all previous unused OTPs of a given type for a user (used on
    // resend)
    @Modifying
    @Query("UPDATE OtpToken o SET o.usedAt = :now WHERE o.user = :user AND o.type = :type AND o.usedAt IS NULL")
    void invalidateAllActiveOtps(User user, OtpType type, OffsetDateTime now);
}
