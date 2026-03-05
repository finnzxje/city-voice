package com.cityvoice.auth.service;

import com.cityvoice.user.entity.OtpToken;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.OtpType;
import com.cityvoice.user.repository.OtpTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpTokenRepository otpTokenRepository;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();

    @Value("${app.otp.verification-expiration-minutes}")
    private int verificationExpiryMinutes;

    @Value("${app.otp.login-expiration-minutes}")
    private int loginExpiryMinutes;

    /**
     * Generates and sends an email verification OTP. Invalidates previous unused
     * ones.
     */
    @Transactional
    public void sendVerificationOtp(User user) {
        otpTokenRepository.invalidateAllActiveOtps(user, OtpType.email_verification, OffsetDateTime.now());
        String otp = generateOtp();
        OtpToken token = OtpToken.builder()
                .user(user)
                .token(otp)
                .type(OtpType.email_verification)
                .expiresAt(OffsetDateTime.now().plusMinutes(verificationExpiryMinutes))
                .build();
        otpTokenRepository.save(token);
        emailService.sendOtpEmail(user.getEmail(), otp, "CityVoice – Xác thực tài khoản");
    }

    /**
     * Generates and sends a login OTP. Invalidates previous unused ones.
     */
    @Transactional
    public void sendLoginOtp(User user) {
        otpTokenRepository.invalidateAllActiveOtps(user, OtpType.login, OffsetDateTime.now());
        String otp = generateOtp();
        OtpToken token = OtpToken.builder()
                .user(user)
                .token(otp)
                .type(OtpType.login)
                .expiresAt(OffsetDateTime.now().plusMinutes(loginExpiryMinutes))
                .build();
        otpTokenRepository.save(token);
        emailService.sendOtpEmail(user.getEmail(), otp, "CityVoice – Mã đăng nhập");
    }

    /**
     * Validates an OTP of a given type. Marks it as used on success.
     * Returns true if valid, false otherwise.
     */
    @Transactional
    public boolean verifyOtp(User user, String otp, OtpType type) {
        return otpTokenRepository
                .findByTokenAndUserAndTypeAndUsedAtIsNullAndExpiresAtAfter(
                        otp, user, type, OffsetDateTime.now())
                .map(token -> {
                    token.setUsedAt(OffsetDateTime.now());
                    otpTokenRepository.save(token);
                    return true;
                })
                .orElse(false);
    }

    private String generateOtp() {
        // 6-digit numeric OTP, zero-padded
        return String.format("%06d", random.nextInt(1_000_000));
    }
}
