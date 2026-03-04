-- V3: Create users table
-- Handles both citizens (OTP auth) and staff/managers (password auth)

CREATE TABLE users (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    full_name       VARCHAR(255),
    role            user_role   NOT NULL DEFAULT 'citizen',
    -- Only populated for staff and manager accounts
    password_hash   TEXT,
    phone_number    VARCHAR(20),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for login lookups
CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_role   ON users(role);
