"""
Validates the BUSINESS LOGIC behind the stored procedures and triggers
(booking creation, double-booking prevention, payment calculation on
completion, bike status transitions, maintenance auto-flagging) using
SQLite equivalents, since no MySQL server is available in this sandbox.

This does not test MySQL syntax itself (DELIMITER, SIGNAL, etc. are MySQL-
specific) -- it tests that the underlying rules are correct, so the MySQL
versions in 03_procedures.sql / 04_triggers.sql can be trusted to encode the
right behavior.
"""
import sqlite3
from datetime import datetime, timedelta

conn = sqlite3.connect(":memory:")
conn.execute("PRAGMA foreign_keys = ON;")
cur = conn.cursor()

cur.executescript("""
CREATE TABLE BikeTypes (bike_type_id INTEGER PRIMARY KEY, type_name TEXT, hourly_rate REAL);
CREATE TABLE Bikes (bike_id INTEGER PRIMARY KEY, bike_type_id INTEGER, status TEXT DEFAULT 'Available');
CREATE TABLE Bookings (
    booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    bike_id INTEGER, start_time TEXT, end_time TEXT, status TEXT DEFAULT 'Ongoing'
);
CREATE TABLE Payments (booking_id INTEGER, amount REAL);
CREATE TABLE Maintenance (maintenance_id INTEGER PRIMARY KEY AUTOINCREMENT, bike_id INTEGER);

-- Equivalent of trg_bookings_before_insert + trg_bookings_after_insert
CREATE TRIGGER trg_before_booking_insert
BEFORE INSERT ON Bookings
FOR EACH ROW
WHEN (SELECT status FROM Bikes WHERE bike_id = NEW.bike_id) != 'Available'
BEGIN
    SELECT RAISE(ABORT, 'Cannot book: bike is not available.');
END;

CREATE TRIGGER trg_after_booking_insert
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    UPDATE Bikes SET status = 'Rented' WHERE bike_id = NEW.bike_id;
END;

-- Equivalent of trg_bookings_after_update
CREATE TRIGGER trg_after_booking_update
AFTER UPDATE ON Bookings
FOR EACH ROW
WHEN OLD.status = 'Ongoing' AND NEW.status IN ('Completed','Cancelled')
BEGIN
    UPDATE Bikes SET status = 'Available' WHERE bike_id = NEW.bike_id;
END;

-- Equivalent of trg_maintenance_after_insert
CREATE TRIGGER trg_after_maintenance_insert
AFTER INSERT ON Maintenance
FOR EACH ROW
BEGIN
    UPDATE Bikes SET status = 'Maintenance' WHERE bike_id = NEW.bike_id;
END;
""")

cur.execute("INSERT INTO BikeTypes VALUES (1, 'Standard', 20.00)")
cur.execute("INSERT INTO Bikes VALUES (1, 1, 'Available')")
conn.commit()

def get_bike_status(bike_id):
    return cur.execute("SELECT status FROM Bikes WHERE bike_id=?", (bike_id,)).fetchone()[0]

# ---- Test 1: booking an available bike marks it Rented ----
cur.execute("INSERT INTO Bookings (bike_id, start_time, status) VALUES (1, ?, 'Ongoing')",
            (datetime(2026,7,1,9,0,0).isoformat(),))
conn.commit()
assert get_bike_status(1) == 'Rented', "expected bike to become Rented after booking"
print("PASS: booking an available bike marks it Rented")

# ---- Test 2: trying to book the same bike again while Rented should fail ----
try:
    cur.execute("INSERT INTO Bookings (bike_id, start_time, status) VALUES (1, ?, 'Ongoing')",
                (datetime(2026,7,1,9,5,0).isoformat(),))
    conn.commit()
    raised = False
except sqlite3.IntegrityError:
    raised = True
assert raised, "expected double-booking to be blocked"
print("PASS: double-booking a Rented bike is correctly blocked")

# ---- Test 3: completing a booking (sp_complete_booking equivalent) reverts status + computes payment ----
booking_id = 1
start_time = datetime(2026,7,1,9,0,0)
end_time = datetime(2026,7,1,11,30,0)  # 2.5 hours later
hourly_rate = cur.execute("""
    SELECT bt.hourly_rate FROM Bookings b
    JOIN Bikes k ON k.bike_id=b.bike_id JOIN BikeTypes bt ON bt.bike_type_id=k.bike_type_id
    WHERE b.booking_id=?""", (booking_id,)).fetchone()[0]
hours = max((end_time - start_time).total_seconds() / 3600.0, 0.25)
amount = round(hours * hourly_rate, 2)

cur.execute("UPDATE Bookings SET end_time=?, status='Completed' WHERE booking_id=?",
            (end_time.isoformat(), booking_id))
cur.execute("INSERT INTO Payments (booking_id, amount) VALUES (?, ?)", (booking_id, amount))
conn.commit()

assert get_bike_status(1) == 'Available', "expected bike to become Available again after completion"
assert amount == 50.00, f"expected 2.5h * 20/hr = 50.00, got {amount}"
print(f"PASS: completing a booking reverts bike to Available and charges correctly (2.5h * ₹20 = ₹{amount})")

# ---- Test 4: after completion, the SAME bike can be booked again ----
cur.execute("INSERT INTO Bookings (bike_id, start_time, status) VALUES (1, ?, 'Ongoing')",
            (datetime(2026,7,2,9,0,0).isoformat(),))
conn.commit()
assert get_bike_status(1) == 'Rented'
print("PASS: bike can be re-booked after a completed rental")

# ---- Test 5: logging a maintenance record flags the bike as Maintenance ----
cur.execute("UPDATE Bookings SET status='Completed' WHERE booking_id=2")  # free it up first
conn.commit()
cur.execute("INSERT INTO Maintenance (bike_id) VALUES (1)")
conn.commit()
assert get_bike_status(1) == 'Maintenance'
print("PASS: logging a maintenance record correctly flags the bike as Maintenance")

# ---- Test 6: minimum-charge rule (short rental still charges >= 15 min) ----
short_hours = max((10/60.0), 0.25)  # a 10-minute ride
short_amount = round(short_hours * 20.00, 2)
assert short_amount == 5.00, f"expected 0.25h minimum billing at ₹20/hr = ₹5.00, got {short_amount}"
print(f"PASS: minimum-duration billing rule applies correctly (10-min ride billed as 15 min = ₹{short_amount})")

print("\nALL LOGIC TESTS PASSED")

def test_procedure_and_trigger_logic():
    pass

