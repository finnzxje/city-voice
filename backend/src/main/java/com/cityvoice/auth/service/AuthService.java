package com.cityvoice.auth.service;

import com.cityvoice.auth.dto.*;
import com.cityvoice.auth.entity.RefreshToken;
import com.cityvoice.security.JwtUtil;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.OtpType;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.RefreshTokenRepository;
import com.cityvoice.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final OtpService otpService;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    // ── Citizen Registration ──────────────────────────────────────

    @Transactional
    public void registerCitizen(CitizenRegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã được đăng ký.");
        }
        User user = User.builder()
                .email(request.email())
                .fullName(request.fullName())
                .phoneNumber(request.phoneNumber())
                .passwordHash(passwordEncoder.encode(request.password()))
                .role(UserRole.citizen)
                .active(false) // inactive until email verified
                .build();
        userRepository.save(user);
        otpService.sendVerificationOtp(user);
    }

    // ── Email Verification ────────────────────────────────────────

    @Transactional
    public void verifyEmail(OtpVerifyRequest request) {
        User user = findActiveOrInactiveUserByEmail(request.email());
        if (user.isActive()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tài khoản đã được xác thực.");
        }
        if (!otpService.verifyOtp(user, request.otp(), OtpType.email_verification)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã OTP không hợp lệ hoặc đã hết hạn.");
        }
        user.setActive(true);
        userRepository.save(user);
    }

    @Transactional
    public void resendVerificationOtp(OtpRequest request) {
        User user = findActiveOrInactiveUserByEmail(request.email());
        if (user.isActive()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tài khoản đã được xác thực.");
        }
        otpService.sendVerificationOtp(user);
    }

    // ── Citizen Login (password) ──────────────────────────────────

    public TokenResponse citizenLoginWithPassword(LoginRequest request) {
        User user = findActiveCitizenByEmail(request.email());
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Thông tin đăng nhập không hợp lệ.");
        }
        return issueTokens(user);
    }

    // ── Citizen Login (OTP) ───────────────────────────────────────

    @Transactional
    public void requestLoginOtp(OtpRequest request) {
        User user = findActiveCitizenByEmail(request.email());
        otpService.sendLoginOtp(user);
    }

    @Transactional
    public TokenResponse verifyLoginOtp(OtpVerifyRequest request) {
        User user = findActiveCitizenByEmail(request.email());
        if (!otpService.verifyOtp(user, request.otp(), OtpType.login)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Mã OTP không hợp lệ hoặc đã hết hạn.");
        }
        return issueTokens(user);
    }

    // ── Staff / Manager / Admin Login ─────────────────────────────

    public TokenResponse staffLogin(LoginRequest request) {
        User user = findUserByEmail(request.email());
        if (user.getRole() == UserRole.citizen) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Vui lòng sử dụng cổng đăng nhập dành cho công dân.");
        }
        if (!user.isActive()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản đã bị vô hiệu hóa.");
        }
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Thông tin đăng nhập không hợp lệ.");
        }
        return issueTokens(user);
    }

    // ── Token Refresh ─────────────────────────────────────────────

    @Transactional
    public TokenResponse refreshTokens(RefreshRequest request) {
        if (!jwtUtil.validateRefreshToken(request.refreshToken())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token không hợp lệ.");
        }
        RefreshToken stored = refreshTokenRepository.findByToken(request.refreshToken())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Không tìm thấy refresh token."));

        if (!stored.isValid()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Refresh token đã hết hạn hoặc bị thu hồi.");
        }
        // Rotate: revoke old token, issue new pair
        stored.setRevokedAt(OffsetDateTime.now());
        refreshTokenRepository.save(stored);
        return issueTokens(stored.getUser());
    }

    // ── Logout ────────────────────────────────────────────────────

    @Transactional
    public void logout(String rawRefreshToken) {
        refreshTokenRepository.findByToken(rawRefreshToken)
                .ifPresent(token -> {
                    token.setRevokedAt(OffsetDateTime.now());
                    refreshTokenRepository.save(token);
                });
    }

    // ── Private helpers ───────────────────────────────────────────

    @Transactional
    protected TokenResponse issueTokens(User user) {
        String accessToken = jwtUtil.generateAccessToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        RefreshToken stored = RefreshToken.builder()
                .user(user)
                .token(refreshToken)
                .expiresAt(OffsetDateTime.now().plusSeconds(refreshExpirationMs / 1000))
                .build();
        refreshTokenRepository.save(stored);

        return TokenResponse.of(accessToken, refreshToken, jwtUtil.getAccessExpirationMs());
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng."));
    }

    private User findActiveCitizenByEmail(String email) {
        User user = findUserByEmail(email);
        if (user.getRole() != UserRole.citizen) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Vui lòng sử dụng cổng đăng nhập dành cho nhân viên.");
        }
        if (!user.isActive()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Tài khoản chưa được xác thực. Vui lòng xác thực email trước.");
        }
        return user;
    }

    private User findActiveOrInactiveUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng."));
    }
}
