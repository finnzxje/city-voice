package com.cityvoice.auth.controller;

import com.cityvoice.auth.dto.*;
import com.cityvoice.auth.service.AuthService;
import com.cityvoice.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // ── Citizen Registration & Verification ───────────────────────

    @PostMapping("/citizen/register")
    public ResponseEntity<Map<String, String>> register(@Valid @RequestBody CitizenRegisterRequest request) {
        authService.registerCitizen(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("message", "Account created. Please check your email for the verification code."));
    }

    @PostMapping("/citizen/verify-email")
    public ResponseEntity<Map<String, String>> verifyEmail(@Valid @RequestBody OtpVerifyRequest request) {
        authService.verifyEmail(request);
        return ResponseEntity.ok(Map.of("message", "Email verified. You can now log in."));
    }

    @PostMapping("/citizen/resend-verification")
    public ResponseEntity<Map<String, String>> resendVerification(@Valid @RequestBody OtpRequest request) {
        authService.resendVerificationOtp(request);
        return ResponseEntity.ok(Map.of("message", "Verification code resent."));
    }

    // ── Citizen Login ─────────────────────────────────────────────

    @PostMapping("/citizen/login")
    public ResponseEntity<TokenResponse> citizenLogin(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.citizenLoginWithPassword(request));
    }

    @PostMapping("/citizen/request-otp")
    public ResponseEntity<Map<String, String>> requestLoginOtp(@Valid @RequestBody OtpRequest request) {
        authService.requestLoginOtp(request);
        return ResponseEntity.ok(Map.of("message", "Login code sent to your email."));
    }

    @PostMapping("/citizen/verify-otp")
    public ResponseEntity<TokenResponse> verifyLoginOtp(@Valid @RequestBody OtpVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyLoginOtp(request));
    }

    // ── Staff / Manager / Admin Login ─────────────────────────────

    @PostMapping("/staff/login")
    public ResponseEntity<TokenResponse> staffLogin(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.staffLogin(request));
    }

    // ── Token Management ──────────────────────────────────────────

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refreshTokens(request));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            @Valid @RequestBody RefreshRequest request,
            @AuthenticationPrincipal User currentUser) {
        authService.logout(request.refreshToken());
        return ResponseEntity.ok(Map.of("message", "Logged out successfully."));
    }

    // ── Current User Info ─────────────────────────────────────────

    @GetMapping("/me")
    public ResponseEntity<UserInfoResponse> me(@AuthenticationPrincipal User currentUser) {
        return ResponseEntity.ok(new UserInfoResponse(
                currentUser.getId(),
                currentUser.getEmail(),
                currentUser.getFullName(),
                currentUser.getRole(),
                currentUser.isActive()));
    }
}
