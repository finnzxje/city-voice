package com.cityvoice.auth.service;

import com.cityvoice.auth.dto.CitizenRegisterRequest;
import com.cityvoice.auth.dto.LoginRequest;
import com.cityvoice.auth.dto.OtpRequest;
import com.cityvoice.auth.dto.OtpVerifyRequest;
import com.cityvoice.auth.dto.TokenResponse;
import com.cityvoice.auth.entity.RefreshToken;
import com.cityvoice.security.JwtUtil;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.OtpType;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.RefreshTokenRepository;
import com.cityvoice.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private RefreshTokenRepository refreshTokenRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtUtil jwtUtil;
    @Mock
    private OtpService otpService;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(authService, "refreshExpirationMs", 604800000L);
    }

    @Test
    void registrationHashesCitizenPasswordAndSendsVerificationOtp() {
        CitizenRegisterRequest request = new CitizenRegisterRequest(
                "citizen@cityvoice.vn", "Citizen@123", "Test Citizen", "0900000000");
        when(userRepository.existsByEmail(request.email())).thenReturn(false);
        when(passwordEncoder.encode(request.password())).thenReturn("encoded-password");

        authService.registerCitizen(request);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User savedUser = captor.getValue();
        assertThat(savedUser.getEmail()).isEqualTo(request.email());
        assertThat(savedUser.getPasswordHash()).isEqualTo("encoded-password");
        assertThat(savedUser.getRole()).isEqualTo(UserRole.citizen);
        assertThat(savedUser.isActive()).isFalse();
        verify(otpService).sendVerificationOtp(savedUser);
    }

    @Test
    void verifiedCitizenCanLoginWithPassword() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(passwordEncoder.matches("Citizen@123", citizen.getPasswordHash())).thenReturn(true);
        stubTokens(citizen);

        TokenResponse response = authService.citizenLoginWithPassword(
                new LoginRequest(citizen.getEmail(), "Citizen@123"));

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    void verifiedCitizenCanRequestLoginOtp() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));

        authService.requestLoginOtp(new OtpRequest(citizen.getEmail()));

        verify(otpService).sendLoginOtp(citizen);
    }

    @Test
    void verifiedCitizenCanLoginWithOtp() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(otpService.verifyOtp(citizen, "123456", OtpType.login)).thenReturn(true);
        stubTokens(citizen);

        TokenResponse response = authService.verifyLoginOtp(
                new OtpVerifyRequest(citizen.getEmail(), "123456"));

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    void unverifiedCitizenCannotLoginWithPassword() {
        User citizen = activeCitizen();
        citizen.setActive(false);
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> authService.citizenLoginWithPassword(
                new LoginRequest(citizen.getEmail(), "Citizen@123")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        ex -> assertThat(ex.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verifyNoInteractions(jwtUtil, refreshTokenRepository);
    }

    @Test
    void invalidLoginOtpDoesNotIssueTokens() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(otpService.verifyOtp(citizen, "000000", OtpType.login)).thenReturn(false);

        assertThatThrownBy(() -> authService.verifyLoginOtp(
                new OtpVerifyRequest(citizen.getEmail(), "000000")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        ex -> assertThat(ex.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));

        verifyNoInteractions(jwtUtil, refreshTokenRepository);
    }

    private User activeCitizen() {
        return User.builder()
                .id(UUID.fromString("11111111-1111-1111-1111-111111111111"))
                .email("citizen@cityvoice.vn")
                .passwordHash("encoded-password")
                .role(UserRole.citizen)
                .active(true)
                .build();
    }

    private void stubTokens(User citizen) {
        when(jwtUtil.generateAccessToken(citizen)).thenReturn("access-token");
        when(jwtUtil.generateRefreshToken(citizen)).thenReturn("refresh-token");
        when(jwtUtil.getAccessExpirationMs()).thenReturn(9000000L);
    }
}
