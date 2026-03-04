-- V2: Create PostgreSQL enum types

-- User roles for RBAC
CREATE TYPE user_role AS ENUM (
    'citizen',
    'staff',
    'manager',
    'admin'
);

-- Report lifecycle states (state machine)
-- Allowed transitions:
--   newly_received → in_progress  (staff accepts)
--   newly_received → rejected     (staff rejects as inauthentic)
--   in_progress    → resolved     (staff uploads proof + marks done)
CREATE TYPE report_status AS ENUM (
    'newly_received',
    'in_progress',
    'resolved',
    'rejected'
);

-- Priority levels, set by staff during review
CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

-- Notification delivery channels
CREATE TYPE notification_channel AS ENUM (
    'email',
    'in_app'
);
