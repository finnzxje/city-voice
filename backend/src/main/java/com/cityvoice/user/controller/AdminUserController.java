package com.cityvoice.user.controller;

import com.cityvoice.auth.dto.UserInfoResponse;
import com.cityvoice.common.dto.ApiResponse;
import com.cityvoice.user.dto.UserRoleUpdateRequest;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final UserService userService;

    @GetMapping("/roles")
    public ResponseEntity<ApiResponse<List<UserRole>>> listRoles() {
        return ResponseEntity.ok(ApiResponse.success(userService.listAllRoles()));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserInfoResponse>>> listUsers() {
        return ResponseEntity.ok(ApiResponse.success(userService.listAllUsers()));
    }

    @PutMapping("/users/{userId}/role")
    public ResponseEntity<ApiResponse<Void>> updateUserRole(
            @PathVariable UUID userId,
            @Valid @RequestBody UserRoleUpdateRequest request) {
        userService.updateUserRole(userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
