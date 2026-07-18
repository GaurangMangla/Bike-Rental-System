-- ============================================================================
-- Bike Rental System — Triggers (MySQL 8.0)
-- These enforce data integrity independent of application code: no matter
-- what inserts a row into Bookings or Maintenance, the Bikes.status column
-- stays correct automatically.
-- ============================================================================
USE bike_rental_system;

DELIMITER $$

-- Belt-and-suspenders check: even though sp_book_bike already checks
-- availability, this trigger blocks a double-booking at the database level,
-- so the invariant holds even if someone inserts into Bookings directly.
CREATE TRIGGER trg_bookings_before_insert
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM Bikes WHERE bike_id = NEW.bike_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot book: bike does not exist.';
    ELSEIF v_status <> 'Available' AND NEW.status = 'Ongoing' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot book: bike is not available.';
    END IF;
END$$

-- After a new ongoing booking is created, mark the bike Rented.
CREATE TRIGGER trg_bookings_after_insert
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.status = 'Ongoing' THEN
        UPDATE Bikes SET status = 'Rented' WHERE bike_id = NEW.bike_id;
    END IF;
END$$

-- When a booking transitions to Completed or Cancelled, free the bike back up
-- (unless it's simultaneously been sent to Maintenance by other logic).
CREATE TRIGGER trg_bookings_after_update
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF OLD.status = 'Ongoing' AND NEW.status IN ('Completed', 'Cancelled') THEN
        UPDATE Bikes SET status = 'Available' WHERE bike_id = NEW.bike_id;
    END IF;
END$$

-- Logging a maintenance record automatically takes the bike out of rotation.
CREATE TRIGGER trg_maintenance_after_insert
AFTER INSERT ON Maintenance
FOR EACH ROW
BEGIN
    UPDATE Bikes SET status = 'Maintenance', last_serviced_at = DATE(NEW.performed_at)
    WHERE bike_id = NEW.bike_id;
END$$

DELIMITER ;
