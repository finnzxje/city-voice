package com.cityvoice.seed;

import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class AdminSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.admin.email}")
    private String adminEmail;

    @Value("${app.admin.password}")
    private String adminPassword;

    @Value("${app.admin.full-name}")
    private String adminFullName;

    @Override
    public void run(String... args) {
        if (userRepository.existsByEmail(adminEmail)) {
            log.info("[AdminSeeder] Admin account already exists: {}", adminEmail);
            return;
        }

        User admin = User.builder()
                .email(adminEmail)
                .fullName(adminFullName)
                .passwordHash(passwordEncoder.encode(adminPassword))
                .role(UserRole.admin)
                .active(true)
                .build();

        userRepository.save(admin);
        log.warn("[AdminSeeder] ⚠ Default admin created: {} — CHANGE THE PASSWORD IMMEDIATELY!", adminEmail);
    }
}
