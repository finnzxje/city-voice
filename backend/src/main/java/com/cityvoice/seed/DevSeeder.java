package com.cityvoice.seed;

import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Seeds a test citizen and test staff account for development use.
 * Runs after AdminSeeder (Order 2). Skipped if the accounts already exist.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@Order(2)
public class DevSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.seed.citizen.email}")
    private String citizenEmail;

    @Value("${app.seed.citizen.password}")
    private String citizenPassword;

    @Value("${app.seed.citizen.full-name}")
    private String citizenFullName;

    @Value("${app.seed.staff.email}")
    private String staffEmail;

    @Value("${app.seed.staff.password}")
    private String staffPassword;

    @Value("${app.seed.staff.full-name}")
    private String staffFullName;

    @Value("${app.seed.manager.email}")
    private String managerEmail;

    @Value("${app.seed.manager.password}")
    private String managerPassword;

    @Value("${app.seed.manager.full-name}")
    private String managerFullName;

    @Override
    public void run(String... args) {
        seedCitizen();
        seedStaff();
        seedManager();
    }

    private void seedCitizen() {
        if (userRepository.existsByEmail(citizenEmail)) {
            log.info("[DevSeeder] Test citizen already exists: {}", citizenEmail);
            return;
        }
        User citizen = User.builder()
                .email(citizenEmail)
                .fullName(citizenFullName)
                .passwordHash(passwordEncoder.encode(citizenPassword))
                .role(UserRole.citizen)
                .active(true)
                .build();
        userRepository.save(citizen);
        log.info("[DevSeeder] Test citizen created: {}", citizenEmail);
    }

    private void seedStaff() {
        if (userRepository.existsByEmail(staffEmail)) {
            log.info("[DevSeeder] Test staff already exists: {}", staffEmail);
            return;
        }
        User staff = User.builder()
                .email(staffEmail)
                .fullName(staffFullName)
                .passwordHash(passwordEncoder.encode(staffPassword))
                .role(UserRole.staff)
                .active(true)
                .build();
        userRepository.save(staff);
        log.info("[DevSeeder] Test staff created: {}", staffEmail);
    }

    private void seedManager() {
        if (userRepository.existsByEmail(managerEmail)) {
            log.info("[DevSeeder] Test manager already exists: {}", managerEmail);
            return;
        }
        User manager = User.builder()
                .email(managerEmail)
                .fullName(managerFullName)
                .passwordHash(passwordEncoder.encode(managerPassword))
                .role(UserRole.manager)
                .active(true)
                .build();
        userRepository.save(manager);
        log.info("[DevSeeder] Test manager created: {}", managerEmail);
    }
}
