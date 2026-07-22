-- ============================================================================
-- Bike Rental System — Analytical / Business Queries (MySQL 8.0)
-- These are the kinds of queries a business analyst would run against this
-- system to answer real operational questions.
-- ============================================================================
USE bike_rental_system;

-- 1. Revenue per location (based on where each rental was picked up)
SELECT
    l.name          AS location_name,
    l.city,
    COUNT(p.payment_id)      AS completed_rentals,
    SUM(p.amount)            AS total_revenue
FROM Payments p
JOIN Bookings b ON b.booking_id = p.booking_id
JOIN Locations l ON l.location_id = b.pickup_location_id
WHERE p.payment_status = 'Paid'
GROUP BY l.location_id, l.name, l.city
ORDER BY total_revenue DESC;

-- 2. Most rented bike types
SELECT
    bt.type_name,
    COUNT(b.booking_id) AS total_bookings
FROM Bookings b
JOIN Bikes k ON k.bike_id = b.bike_id
JOIN BikeTypes bt ON bt.bike_type_id = k.bike_type_id
WHERE b.status = 'Completed'
GROUP BY bt.bike_type_id, bt.type_name
ORDER BY total_bookings DESC;

-- 3. Top customers by total spend
SELECT
    u.full_name,
    u.email,
    COUNT(p.payment_id)  AS total_rentals,
    SUM(p.amount)         AS total_spent
FROM Payments p
JOIN Bookings b ON b.booking_id = p.booking_id
JOIN Users u ON u.user_id = b.user_id
WHERE p.payment_status = 'Paid'
GROUP BY u.user_id, u.full_name, u.email
ORDER BY total_spent DESC
LIMIT 10;

-- 4. Average rating per bike type (customer satisfaction by product line)
SELECT
    bt.type_name,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id)      AS num_reviews
FROM Reviews r
JOIN Bookings b ON b.booking_id = r.booking_id
JOIN Bikes k ON k.bike_id = b.bike_id
JOIN BikeTypes bt ON bt.bike_type_id = k.bike_type_id
GROUP BY bt.bike_type_id, bt.type_name
ORDER BY avg_rating DESC;

-- 5. Bike utilization: number of completed rentals per bike (identifies
--    over- and under-used bikes across the fleet)
SELECT
    bk.bike_id,
    bt.type_name,
    l.name AS home_location,
    COUNT(b.booking_id) AS times_rented
FROM Bikes bk
JOIN BikeTypes bt ON bt.bike_type_id = bk.bike_type_id
JOIN Locations l ON l.location_id = bk.location_id
LEFT JOIN Bookings b ON b.bike_id = bk.bike_id AND b.status = 'Completed'
GROUP BY bk.bike_id, bt.type_name, l.name
ORDER BY times_rented DESC;

-- 6. Monthly revenue trend
SELECT
    DATE_FORMAT(p.paid_at, '%Y-%m') AS month,
    SUM(p.amount) AS revenue
FROM Payments p
WHERE p.payment_status = 'Paid'
GROUP BY DATE_FORMAT(p.paid_at, '%Y-%m')
ORDER BY month;

-- 7. Currently ongoing bookings that have run longer than 4 hours
--    (an "overdue rental" alert a business analyst would monitor daily)
SELECT
    b.booking_id,
    u.full_name,
    bk.bike_id,
    b.start_time,
    TIMESTAMPDIFF(HOUR, b.start_time, NOW()) AS hours_elapsed
FROM Bookings b
JOIN Users u ON u.user_id = b.user_id
JOIN Bikes bk ON bk.bike_id = b.bike_id
WHERE b.status = 'Ongoing'
  AND TIMESTAMPDIFF(HOUR, b.start_time, NOW()) > 4
ORDER BY hours_elapsed DESC;

-- 8. Fleet status breakdown (how many bikes are Available / Rented /
--    Maintenance / Retired right now, per location) -- a quick ops dashboard query
SELECT
    l.name AS location_name,
    bk.status,
    COUNT(*) AS bike_count
FROM Bikes bk
JOIN Locations l ON l.location_id = bk.location_id
GROUP BY l.location_id, l.name, bk.status
ORDER BY l.name, bk.status;
