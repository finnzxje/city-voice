package com.cityvoice.user.service;

import com.cityvoice.auth.dto.UserInfoResponse;
import com.cityvoice.user.dto.UserRoleUpdateRequest;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    public List<UserRole> listAllRoles() {
        return Arrays.asList(UserRole.values());
    }

    @Transactional(readOnly = true)
    public List<UserInfoResponse> listAllUsers() {
        return userRepository.findAll().stream()
                .map(u -> new UserInfoResponse(u.getId(), u.getEmail(), u.getFullName(), u.getRole(), u.isActive()))
                .toList();
    }
    @Transactional
    public User updateUserRole(UUID userId, UserRoleUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng"));
        user.setRole(request.getRole());
        return userRepository.save(user);
    }
}
