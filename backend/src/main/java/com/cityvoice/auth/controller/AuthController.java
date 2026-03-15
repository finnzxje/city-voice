package com.cityvoice.auth.controller;

import com.cityvoice.auth.dto.*;
import com.cityvoice.auth.service.AuthService;
import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // ── Citizen Registration & Verification ───────────────────────

    @PostMapping("/citizen/register")
    public ResponseEntity<ApiResponse<Void>> register(@Valid @RequestBody CitizenRegisterRequest request) {
        authService.registerCitizen(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tài khoản đã được tạo. Vui lòng kiểm tra email để lấy mã xác thực.", null));
    }

    @PostMapping("/citizen/verify-email")
    public ResponseEntity<ApiResponse<Void>> verifyEmail(@Valid @RequestBody OtpVerifyRequest request) {
        authService.verifyEmail(request);
        return ResponseEntity
                .ok(ApiResponse.success("Email đã được xác thực. Bạn có thể đăng nhập ngay bây giờ.", null));
    }

    @PostMapping("/citizen/resend-verification")
    public ResponseEntity<ApiResponse<Void>> resendVerification(@Valid @RequestBody OtpRequest request) {
        authService.resendVerificationOtp(request);
        return ResponseEntity.ok(ApiResponse.success("Mã xác thực đã được gửi lại.", null));
    }

    // ── Citizen Login ─────────────────────────────────────────────

    @PostMapping("/citizen/login")
    public ResponseEntity<ApiResponse<TokenResponse>> citizenLogin(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.citizenLoginWithPassword(request)));
    }

    @PostMapping("/citizen/request-otp")
    public ResponseEntity<ApiResponse<Void>> requestLoginOtp(@Valid @RequestBody OtpRequest request) {
        authService.requestLoginOtp(request);
        return ResponseEntity.ok(ApiResponse.success("Mã đăng nhập đã được gửi đến email của bạn.", null));
    }

    @PostMapping("/citizen/verify-otp")
    public ResponseEntity<ApiResponse<TokenResponse>> verifyLoginOtp(@Valid @RequestBody OtpVerifyRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.verifyLoginOtp(request)));
    }

    // ── Staff / Manager / Admin Login ─────────────────────────────

    @PostMapping("/staff/login")
    public ResponseEntity<ApiResponse<TokenResponse>> staffLogin(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.staffLogin(request)));
    }

    // ── Token Management ──────────────────────────────────────────

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<TokenResponse>> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.refreshTokens(request)));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Valid @RequestBody RefreshRequest request,
            @AuthenticationPrincipal User currentUser) {
        authService.logout(request.refreshToken());
        return ResponseEntity.ok(ApiResponse.success("Đăng xuất thành công.", null));
    }

    // ── Current User Info ─────────────────────────────────────────

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserInfoResponse>> me(@AuthenticationPrincipal User currentUser) {
        return ResponseEntity.ok(ApiResponse.success(new UserInfoResponse(
                currentUser.getId(),
                currentUser.getEmail(),
                currentUser.getFullName(),
                currentUser.getRole(),
                currentUser.isActive())));
    }
}
