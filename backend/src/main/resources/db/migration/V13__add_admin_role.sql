-- V13: Add 'admin' value to user_role enum
-- Note: PostgreSQL does not allow ALTER TYPE ... ADD VALUE inside a transaction block
-- Flyway workaround: use a DO block or set autoCommit.
-- In PostgreSQL 12+, ADD VALUE IF NOT EXISTS is idempotent.
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';
