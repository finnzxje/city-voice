package com.cityvoice.security;

import com.cityvoice.user.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtUtil {

    @Value("${app.jwt.access-secret}")
    private String accessSecret;

    @Value("${app.jwt.access-expiration-ms}")
    private long accessExpirationMs;

    @Value("${app.jwt.refresh-secret}")
    private String refreshSecret;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    // ── Access Token ─────────────────────────────────────────────

    public String generateAccessToken(User user) {
        return Jwts.builder()
                .subject(user.getId().toString())
                .claim("role", user.getRole().name())
                .claim("email", user.getEmail())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessExpirationMs))
                .signWith(getAccessKey())
                .compact();
    }

    public boolean validateAccessToken(String token) {
        return validate(token, getAccessKey());
    }

    public UUID extractUserIdFromAccessToken(String token) {
        return UUID.fromString(extractClaims(token, getAccessKey()).getSubject());
    }

    // ── Refresh Token ─────────────────────────────────────────────

    public String generateRefreshToken(User user) {
        return Jwts.builder()
                .id(java.util.UUID.randomUUID().toString()) // unique jti prevents duplicate tokens
                .subject(user.getId().toString())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + refreshExpirationMs))
                .signWith(getRefreshKey())
                .compact();
    }

    public boolean validateRefreshToken(String token) {
        return validate(token, getRefreshKey());
    }

    public UUID extractUserIdFromRefreshToken(String token) {
        return UUID.fromString(extractClaims(token, getRefreshKey()).getSubject());
    }

    // ── Expiry helpers ────────────────────────────────────────────

    public long getAccessExpirationMs() {
        return accessExpirationMs;
    }

    public long getRefreshExpirationMs() {
        return refreshExpirationMs;
    }

    // ── Private helpers ───────────────────────────────────────────

    private boolean validate(String token, SecretKey key) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private Claims extractClaims(String token, SecretKey key) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey getAccessKey() {
        return Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
    }

    private SecretKey getRefreshKey() {
        return Keys.hmacShaKeyFor(refreshSecret.getBytes(StandardCharsets.UTF_8));
    }
}
