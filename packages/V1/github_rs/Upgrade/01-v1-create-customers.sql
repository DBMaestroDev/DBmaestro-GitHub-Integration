CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(255),
    created_at TIMESTAMP DEFAULT now()
);

-- Pre-2024 customer records, kept read-only after the CRM migration.
CREATE TABLE customers_legacy (
    id          INTEGER PRIMARY KEY,
    name        VARCHAR(100),
    email       VARCHAR(255),
    migrated_at TIMESTAMP
);
