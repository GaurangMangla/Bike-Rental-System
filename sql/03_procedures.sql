-- ============================================================================
-- Bike Rental System — Stored Procedures (MySQL 8.0)
-- ============================================================================
USE bike_rental_system;

DELIMITER $$

-- ----------------------------------------------------------------------------
-- sp_book_bike: creates a new booking for an available bike.
-- The actual "mark the bike as Rented" step is handled by a trigger
-- (trg_bikes_after_booking_insert in 04_triggers.sql), not here — that keeps
-- the invariant "a bike's status always reflects its booking history" true
-- even if bookings are ever inserted from somewhere other than this procedure.
-- ----------------------------------------------------------------------------
CREATE PROCEDURE sp_book_bike (
    IN  p_user_id             INT,
    IN  p_bike_id             INT,
    IN  p_pickup_location_id  INT,
    OUT p_booking_id          INT,
    OUT p_message             VARCHAR(255)
)
BEGIN
    DECLARE v_bike_status VARCHAR(20);

    SELECT status INTO v_bike_status FROM Bikes WHERE bike_id = p_bike_id FOR UPDATE;

    IF v_bike_status IS NULL THEN
        SET p_booking_id = NULL;
        SET p_message = 'Bike does not exist.';
    ELSEIF v_bike_status <> 'Available' THEN
        SET p_booking_id = NULL;
        SET p_message = CONCAT('Bike is not available (current status: ', v_bike_status, ').');
    ELSE
        INSERT INTO Bookings (user_id, bike_id, pickup_location_id, start_time, status)
        VALUES (p_user_id, p_bike_id, p_pickup_location_id, NOW(), 'Ongoing');

        SET p_booking_id = LAST_INSERT_ID();
        SET p_message = 'Booking created successfully.';
    END IF;
END$$

-- ----------------------------------------------------------------------------
-- sp_complete_booking: ends a rental, computes the payment based on the
-- bike type's hourly rate and actual duration, and records the payment.
-- Bike status reverts to Available via trigger, not here.
-- ----------------------------------------------------------------------------
CREATE PROCEDURE sp_complete_booking (
    IN  p_booking_id          INT,
    IN  p_dropoff_location_id INT,
    IN  p_payment_method      VARCHAR(20),
    OUT p_amount_charged      DECIMAL(8,2),
    OUT p_message             VARCHAR(255)
)
BEGIN
    DECLARE v_status       VARCHAR(20);
    DECLARE v_start_time   DATETIME;
    DECLARE v_hourly_rate  DECIMAL(6,2);
    DECLARE v_hours        DECIMAL(8,4);

    SELECT b.status, b.start_time, bt.hourly_rate
        INTO v_status, v_start_time, v_hourly_rate
    FROM Bookings b
    JOIN Bikes k ON k.bike_id = b.bike_id
    JOIN BikeTypes bt ON bt.bike_type_id = k.bike_type_id
    WHERE b.booking_id = p_booking_id;

    IF v_status IS NULL THEN
        SET p_amount_charged = NULL;
        SET p_message = 'Booking does not exist.';
    ELSEIF v_status <> 'Ongoing' THEN
        SET p_amount_charged = NULL;
        SET p_message = CONCAT('Booking is not ongoing (current status: ', v_status, ').');
    ELSE
        -- Duration in hours, minimum billed as 0.25h (15 min) to avoid zero-charge edge cases
        SET v_hours = GREATEST(TIMESTAMPDIFF(SECOND, v_start_time, NOW()) / 3600.0, 0.25);
        SET p_amount_charged = ROUND(v_hours * v_hourly_rate, 2);

        UPDATE Bookings
        SET end_time = NOW(), status = 'Completed', dropoff_location_id = p_dropoff_location_id
        WHERE booking_id = p_booking_id;

        INSERT INTO Payments (booking_id, amount, payment_method, payment_status, paid_at)
        VALUES (p_booking_id, p_amount_charged, p_payment_method, 'Paid', NOW());

        SET p_message = 'Booking completed and payment recorded.';
    END IF;
END$$

-- ----------------------------------------------------------------------------
-- sp_cancel_booking: cancels an ongoing booking (e.g. user changed their mind
-- before actually taking the bike). Bike status reverts via trigger.
-- ----------------------------------------------------------------------------
CREATE PROCEDURE sp_cancel_booking (
    IN  p_booking_id INT,
    OUT p_message    VARCHAR(255)
)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM Bookings WHERE booking_id = p_booking_id;

    IF v_status IS NULL THEN
        SET p_message = 'Booking does not exist.';
    ELSEIF v_status <> 'Ongoing' THEN
        SET p_message = CONCAT('Only ongoing bookings can be cancelled (current status: ', v_status, ').');
    ELSE
        UPDATE Bookings SET status = 'Cancelled', end_time = NOW() WHERE booking_id = p_booking_id;
        SET p_message = 'Booking cancelled.';
    END IF;
END$$

DELIMITER ;
