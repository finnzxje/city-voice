-- V4: OTP tokens table for citizen email authentication

CREATE TABLE otp_tokens (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 6-digit numeric OTP padded to string
    token       VARCHAR(8)  NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    -- NULL = not yet consumed; set when citizen successfully verifies
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_tokens_user_id    ON otp_tokens(user_id);
CREATE INDEX idx_otp_tokens_expires_at ON otp_tokens(expires_at);
