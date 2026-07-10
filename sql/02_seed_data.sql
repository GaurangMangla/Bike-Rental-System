-- ============================================================================
-- Bike Rental System — Seed Data
-- Realistic sample data so the schema, procedures, triggers, and queries
-- can all be demonstrated end to end.
-- ============================================================================
USE bike_rental_system;

-- Locations
INSERT INTO Locations (name, city, address) VALUES
('MG Road Hub', 'Bengaluru', '12 MG Road, Bengaluru'),
('Connaught Place Hub', 'Delhi', '5 Connaught Place, Delhi'),
('Baner Hub', 'Pune', '88 Baner Road, Pune'),
('Koramangala Hub', 'Bengaluru', '4th Block, Koramangala, Bengaluru');

-- Bike types (this is where pricing lives — normalized out of the Bikes table)
INSERT INTO BikeTypes (type_name, hourly_rate, deposit_amount) VALUES
('Standard', 20.00, 200.00),
('Electric', 45.00, 500.00),
('Mountain', 30.00, 300.00);

-- Admins
INSERT INTO Admins (full_name, email, password_hash, role) VALUES
('Ritika Sharma', 'ritika.admin@bikesys.com', 'hash_placeholder_1', 'SuperAdmin'),
('Arjun Verma', 'arjun.admin@bikesys.com', 'hash_placeholder_2', 'LocationManager');

-- Users
INSERT INTO Users (full_name, email, phone, password_hash) VALUES
('Aditi Rao', 'aditi.rao@example.com', '9800000001', 'hash_u1'),
('Karan Mehta', 'karan.mehta@example.com', '9800000002', 'hash_u2'),
('Sneha Iyer', 'sneha.iyer@example.com', '9800000003', 'hash_u3'),
('Vikram Nair', 'vikram.nair@example.com', '9800000004', 'hash_u4'),
('Priya Das', 'priya.das@example.com', '9800000005', 'hash_u5'),
('Rohit Kapoor', 'rohit.kapoor@example.com', '9800000006', 'hash_u6');

-- Bikes: mix of types and locations, mostly Available so the demo procedures
-- (booking, etc.) have something to work with.
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

-- Historical bookings (already completed, for analytics) --------------------
-- Booking 1: Aditi rents a Standard bike at MG Road Hub for 2.5 hours
INSERT INTO Bookings (user_id, bike_id, pickup_location_id, dropoff_location_id, start_time, end_time, status) VALUES
(1, 1, 1, 1, '2026-07-01 09:00:00', '2026-07-01 11:30:00', 'Completed'),
(2, 4, 2, 2, '2026-07-02 10:00:00', '2026-07-02 12:00:00', 'Completed'),
(3, 6, 3, 3, '2026-07-03 14:00:00', '2026-07-03 15:15:00', 'Completed'),
(4, 8, 4, 4, '2026-07-04 08:30:00', '2026-07-04 09:45:00', 'Completed'),
(5, 9, 4, 4, '2026-07-05 16:00:00', '2026-07-05 18:00:00', 'Completed'),
(1, 2, 1, 1, '2026-07-06 11:00:00', '2026-07-06 12:30:00', 'Completed'),
(6, 5, 2, 2, '2026-07-07 09:00:00', '2026-07-07 09:40:00', 'Cancelled');

-- Corresponding payments for completed bookings (amount = hourly_rate * duration, rounded)
INSERT INTO Payments (booking_id, amount, payment_method, payment_status, paid_at) VALUES
(1, 50.00, 'UPI', 'Paid', '2026-07-01 11:31:00'),
(2, 60.00, 'Card', 'Paid', '2026-07-02 12:01:00'),
(3, 56.25, 'Wallet', 'Paid', '2026-07-03 15:16:00'),
(4, 25.00, 'UPI', 'Paid', '2026-07-04 09:46:00'),
(5, 90.00, 'Card', 'Paid', '2026-07-05 18:01:00'),
(6, 41.67, 'Cash', 'Paid', '2026-07-06 12:31:00');

-- Reviews for completed bookings
INSERT INTO Reviews (booking_id, rating, comment) VALUES
(1, 5, 'Smooth ride, bike was in great condition.'),
(2, 4, 'Good experience, pickup was quick.'),
(3, 3, 'Bike gears were a bit stiff.'),
(4, 5, 'Loved the electric bike!'),
(5, 4, 'Great for the evening commute.');

-- A maintenance record for the bike currently in Maintenance status
INSERT INTO Maintenance (bike_id, admin_id, description, cost, performed_at) VALUES
(7, 2, 'Brake pad replacement and gear tuning', 450.00, '2026-07-08 10:00:00');
