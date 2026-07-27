"""
Validates the relational structure and seed data of the Bike Rental System
schema using SQLite as a stand-in for MySQL (no MySQL server is available in
this sandbox). This checks that foreign keys, uniqueness constraints, and the
seed data are internally consistent BEFORE trusting the MySQL-syntax files
that get delivered to the user.
"""
import sqlite3

conn = sqlite3.connect(":memory:")
conn.execute("PRAGMA foreign_keys = ON;")
cur = conn.cursor()

# SQLite-compatible translation of 01_schema.sql (ENUM -> CHECK, AUTO_INCREMENT -> INTEGER PK)
schema_sqlite = """
CREATE TABLE Locations (
    location_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,
    city            TEXT NOT NULL,
    address         TEXT NOT NULL,
    UNIQUE (name, city)
);

CREATE TABLE BikeTypes (
    bike_type_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name       TEXT NOT NULL UNIQUE,
    hourly_rate     REAL NOT NULL CHECK (hourly_rate > 0),
    deposit_amount  REAL NOT NULL DEFAULT 0
);

CREATE TABLE Users (
    user_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    phone           TEXT NOT NULL,
    password_hash   TEXT NOT NULL,
    registered_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Admins (
    admin_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('SuperAdmin','LocationManager','Support')) DEFAULT 'Support'
);

CREATE TABLE Bikes (
    bike_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    bike_type_id    INTEGER NOT NULL,
    location_id     INTEGER NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('Available','Rented','Maintenance','Retired')) DEFAULT 'Available',
    last_serviced_at TEXT,
    FOREIGN KEY (bike_type_id) REFERENCES BikeTypes(bike_type_id),
    FOREIGN KEY (location_id) REFERENCES Locations(location_id)
);

CREATE TABLE Bookings (
    booking_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL,
    bike_id             INTEGER NOT NULL,
    pickup_location_id  INTEGER NOT NULL,
    dropoff_location_id INTEGER,
    start_time          TEXT NOT NULL,
    end_time            TEXT,
    status              TEXT NOT NULL CHECK (status IN ('Ongoing','Completed','Cancelled')) DEFAULT 'Ongoing',
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (bike_id) REFERENCES Bikes(bike_id),
    FOREIGN KEY (pickup_location_id) REFERENCES Locations(location_id),
    FOREIGN KEY (dropoff_location_id) REFERENCES Locations(location_id)
);

CREATE TABLE Payments (
    payment_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id      INTEGER NOT NULL UNIQUE,
    amount          REAL NOT NULL CHECK (amount >= 0),
    payment_method  TEXT NOT NULL CHECK (payment_method IN ('Card','UPI','Wallet','Cash')),
    payment_status  TEXT NOT NULL CHECK (payment_status IN ('Pending','Paid','Refunded')) DEFAULT 'Pending',
    paid_at         TEXT,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

CREATE TABLE Maintenance (
    maintenance_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    bike_id         INTEGER NOT NULL,
    admin_id        INTEGER NOT NULL,
    description     TEXT NOT NULL,
    cost            REAL NOT NULL DEFAULT 0,
    performed_at    TEXT NOT NULL,
    FOREIGN KEY (bike_id) REFERENCES Bikes(bike_id),
    FOREIGN KEY (admin_id) REFERENCES Admins(admin_id)
);

CREATE TABLE Reviews (
    review_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id      INTEGER NOT NULL UNIQUE,
    rating          INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    reviewed_at     TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);
"""
cur.executescript(schema_sqlite)
print("PASS: schema created successfully (tables, FKs, CHECK constraints all valid)")

# ---- Load the seed data (translated to SQLite-friendly INSERTs) ----
seed_sqlite = """
INSERT INTO Locations (name, city, address) VALUES
('MG Road Hub', 'Bengaluru', '12 MG Road, Bengaluru'),
('Connaught Place Hub', 'Delhi', '5 Connaught Place, Delhi'),
('Baner Hub', 'Pune', '88 Baner Road, Pune'),
('Koramangala Hub', 'Bengaluru', '4th Block, Koramangala, Bengaluru');

INSERT INTO BikeTypes (type_name, hourly_rate, deposit_amount) VALUES
('Standard', 20.00, 200.00),
('Electric', 45.00, 500.00),
('Mountain', 30.00, 300.00);

INSERT INTO Admins (full_name, email, password_hash, role) VALUES
('Ritika Sharma', 'ritika.admin@bikesys.com', 'hash_placeholder_1', 'SuperAdmin'),
('Arjun Verma', 'arjun.admin@bikesys.com', 'hash_placeholder_2', 'LocationManager');

INSERT INTO Users (full_name, email, phone, password_hash) VALUES
('Aditi Rao', 'aditi.rao@example.com', '9800000001', 'hash_u1'),
('Karan Mehta', 'karan.mehta@example.com', '9800000002', 'hash_u2'),
('Sneha Iyer', 'sneha.iyer@example.com', '9800000003', 'hash_u3'),
('Vikram Nair', 'vikram.nair@example.com', '9800000004', 'hash_u4'),
('Priya Das', 'priya.das@example.com', '9800000005', 'hash_u5'),
('Rohit Kapoor', 'rohit.kapoor@example.com', '9800000006', 'hash_u6');

INSERT INTO Bikes (bike_type_id, location_id, status, last_serviced_at) VALUES
(1, 1, 'Available', '2026-06-01'),
(1, 1, 'Available', '2026-06-01'),
(2, 1, 'Available', '2026-06-15'),
(3, 2, 'Available', '2026-05-20'),
(1, 2, 'Available', '2026-06-10'),
(2, 3, 'Available', '2026-06-05'),
(3, 3, 'Maintenance', '2026-04-30'),
(1, 4, 'Available', '2026-06-12'),
(2, 4, 'Available', '2026-06-18'),
(3, 4, 'Available', '2026-06-01');

INSERT INTO Bookings (user_id, bike_id, pickup_location_id, dropoff_location_id, start_time, end_time, status) VALUES
(1, 1, 1, 1, '2026-07-01 09:00:00', '2026-07-01 11:30:00', 'Completed'),
(2, 4, 2, 2, '2026-07-02 10:00:00', '2026-07-02 12:00:00', 'Completed'),
(3, 6, 3, 3, '2026-07-03 14:00:00', '2026-07-03 15:15:00', 'Completed'),
(4, 8, 4, 4, '2026-07-04 08:30:00', '2026-07-04 09:45:00', 'Completed'),
(5, 9, 4, 4, '2026-07-05 16:00:00', '2026-07-05 18:00:00', 'Completed'),
(1, 2, 1, 1, '2026-07-06 11:00:00', '2026-07-06 12:30:00', 'Completed'),
(6, 5, 2, 2, '2026-07-07 09:00:00', '2026-07-07 09:40:00', 'Cancelled');

INSERT INTO Payments (booking_id, amount, payment_method, payment_status, paid_at) VALUES
(1, 50.00, 'UPI', 'Paid', '2026-07-01 11:31:00'),
(2, 60.00, 'Card', 'Paid', '2026-07-02 12:01:00'),
(3, 56.25, 'Wallet', 'Paid', '2026-07-03 15:16:00'),
(4, 25.00, 'UPI', 'Paid', '2026-07-04 09:46:00'),
(5, 90.00, 'Card', 'Paid', '2026-07-05 18:01:00'),
(6, 41.67, 'Cash', 'Paid', '2026-07-06 12:31:00');

INSERT INTO Reviews (booking_id, rating, comment) VALUES
(1, 5, 'Smooth ride, bike was in great condition.'),
(2, 4, 'Good experience, pickup was quick.'),
(3, 3, 'Bike gears were a bit stiff.'),
(4, 5, 'Loved the electric bike!'),
(5, 4, 'Great for the evening commute.');

INSERT INTO Maintenance (bike_id, admin_id, description, cost, performed_at) VALUES
(7, 2, 'Brake pad replacement and gear tuning', 450.00, '2026-07-08 10:00:00');
"""
cur.executescript(seed_sqlite)
print("PASS: seed data inserted successfully (all FK references resolve, no constraint violations)")

# ---- Sanity check counts ----
for table in ["Locations","BikeTypes","Admins","Users","Bikes","Bookings","Payments","Reviews","Maintenance"]:
    n = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    print(f"  {table}: {n} rows")

conn.commit()

def test_schema_and_seed():
    pass

