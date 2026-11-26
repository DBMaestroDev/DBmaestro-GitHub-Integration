CREATE TABLE orders (
    id          SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers (id),
    total       NUMERIC(12,2) NOT NULL,
    ordered_at  TIMESTAMP DEFAULT now()
);
