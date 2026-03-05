package com.cityvoice.auth.dto;

import com.cityvoice.user.enums.UserRole;

import java.util.UUID;

public record UserInfoResponse(
        UUID id,
        String email,
        String fullName,
        UserRole role,
        boolean isActive) {
}
