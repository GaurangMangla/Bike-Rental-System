-- ============================================================================
-- Bike Rental System — Schema (MySQL 8.0)
-- Normalized to 3NF: pricing lives on BikeTypes (not repeated per bike),
-- locations are a lookup table, and every transactional fact table references
-- its dimension tables by foreign key rather than duplicating text data.
-- ============================================================================

DROP DATABASE IF EXISTS bike_rental_system;
CREATE DATABASE bike_rental_system CHARACTER SET utf8mb4;
USE bike_rental_system;

-- ----------------------------------------------------------------------------
-- Dimension tables
-- ----------------------------------------------------------------------------

CREATE TABLE Locations (
    location_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    address         VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_location_name_city (name, city)
) ENGINE=InnoDB;

CREATE TABLE BikeTypes (
    bike_type_id    INT AUTO_INCREMENT PRIMARY KEY,
    type_name       VARCHAR(50) NOT NULL UNIQUE,      -- e.g. Standard, Electric, Mountain
    hourly_rate     DECIMAL(6,2) NOT NULL CHECK (hourly_rate > 0),
    deposit_amount  DECIMAL(8,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE Users (
    user_id         INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    phone           VARCHAR(20)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    registered_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Admins (
    admin_id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    role            ENUM('SuperAdmin','LocationManager','Support') NOT NULL DEFAULT 'Support'
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Bikes: one row per physical bike; status is maintained by triggers, not
-- updated ad-hoc by application code, so it can never silently drift out of sync.
-- ----------------------------------------------------------------------------

CREATE TABLE Bikes (
    bike_id         INT AUTO_INCREMENT PRIMARY KEY,
    bike_type_id    INT NOT NULL,
    location_id     INT NOT NULL,     -- current/home location of the bike
    status          ENUM('Available','Rented','Maintenance','Retired') NOT NULL DEFAULT 'Available',
    last_serviced_at DATE NULL,
    CONSTRAINT fk_bikes_type FOREIGN KEY (bike_type_id) REFERENCES BikeTypes(bike_type_id),
    CONSTRAINT fk_bikes_location FOREIGN KEY (location_id) REFERENCES Locations(location_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Bookings: the core transactional table.
-- ----------------------------------------------------------------------------

CREATE TABLE Bookings (
    booking_id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL,
    bike_id             INT NOT NULL,
    pickup_location_id  INT NOT NULL,
    dropoff_location_id INT NULL,           -- filled in when the ride completes
    start_time          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time            DATETIME NULL,
    status              ENUM('Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Ongoing',
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_booking_bike FOREIGN KEY (bike_id) REFERENCES Bikes(bike_id),
    CONSTRAINT fk_booking_pickup FOREIGN KEY (pickup_location_id) REFERENCES Locations(location_id),
    CONSTRAINT fk_booking_dropoff FOREIGN KEY (dropoff_location_id) REFERENCES Locations(location_id),
    CONSTRAINT chk_booking_times CHECK (end_time IS NULL OR end_time > start_time)
) ENGINE=InnoDB;

CREATE TABLE Payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL UNIQUE,     -- one payment per booking
    amount          DECIMAL(8,2) NOT NULL CHECK (amount >= 0),
    payment_method  ENUM('Card','UPI','Wallet','Cash') NOT NULL,
    payment_status  ENUM('Pending','Paid','Refunded') NOT NULL DEFAULT 'Pending',
    paid_at         DATETIME NULL,
    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
) ENGINE=InnoDB;

CREATE TABLE Maintenance (
    maintenance_id  INT AUTO_INCREMENT PRIMARY KEY,
    bike_id         INT NOT NULL,
    admin_id        INT NOT NULL,
    description     VARCHAR(255) NOT NULL,
    cost            DECIMAL(8,2) NOT NULL DEFAULT 0,
    performed_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_maintenance_bike FOREIGN KEY (bike_id) REFERENCES Bikes(bike_id),
    CONSTRAINT fk_maintenance_admin FOREIGN KEY (admin_id) REFERENCES Admins(admin_id)
) ENGINE=InnoDB;

CREATE TABLE Reviews (
    review_id       INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL UNIQUE,     -- one review per completed booking
    rating          TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         VARCHAR(500) NULL,
    reviewed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_review_booking FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Indexes to support the analytical queries in 04_queries.sql
-- ----------------------------------------------------------------------------
CREATE INDEX idx_bookings_bike ON Bookings(bike_id);
CREATE INDEX idx_bookings_user ON Bookings(user_id);
CREATE INDEX idx_bookings_status ON Bookings(status);
CREATE INDEX idx_bikes_location ON Bikes(location_id);
