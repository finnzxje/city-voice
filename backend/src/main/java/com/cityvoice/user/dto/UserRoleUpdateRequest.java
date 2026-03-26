package com.cityvoice.user.dto;

import com.cityvoice.user.enums.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UserRoleUpdateRequest {

    @NotNull(message = "Vai trò không được để trống")
    private UserRole role;
}
