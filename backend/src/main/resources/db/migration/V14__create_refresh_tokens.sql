-- V14: Add otp_type enum and refresh_tokens table

-- OTP type distinguishes email verification OTPs from login OTPs
CREATE TYPE otp_type AS ENUM (
    'email_verification',
    'login'
);

-- Add otp_type column to existing otp_tokens table
ALTER TABLE otp_tokens ADD COLUMN type otp_type NOT NULL DEFAULT 'login';

-- Refresh tokens table — stores opaque refresh tokens with revocation support
CREATE TABLE refresh_tokens (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- The opaque refresh token string (SHA-256 hashed for storage)
    token       TEXT        NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    -- NULL = active; set when user logs out or token is rotated
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token   ON refresh_tokens(token);
-- Partial index for fast lookup of active (non-revoked) tokens
CREATE INDEX idx_refresh_tokens_active  ON refresh_tokens(token) WHERE revoked_at IS NULL;
