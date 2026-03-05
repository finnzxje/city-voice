package com.cityvoice.auth.dto;

import com.cityvoice.user.enums.UserRole;

import java.util.UUID;

public record TokenResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long accessExpiresIn) {
    public static TokenResponse of(String accessToken, String refreshToken, long accessExpiresInMs) {
        return new TokenResponse(accessToken, refreshToken, "Bearer", accessExpiresInMs / 1000);
    }
}
