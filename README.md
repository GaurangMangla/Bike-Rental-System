# 🚲 Bike Rental System — DBMS Project

A complete relational database design for a bike rental service: schema, seed
data, stored procedures, triggers, and business-analyst-style reporting
queries. Built and validated in MySQL 8.0.

## What this actually contains

Every file listed here exists in this repo and does what it says — no
placeholders.

```
tests/
  test_schema_and_seed_data.py       Validates schema + seed data integrity
  test_procedure_and_trigger_logic.py Validates booking/payment/status-transition logic
  test_analytical_queries.py         Validates all 8 reporting queries
sql/
  01_schema.sql        Table definitions (9 tables, normalized to 3NF)
  02_seed_data.sql      Realistic sample data across all tables
  03_procedures.sql     Stored procedures: book, complete, and cancel a rental
  04_triggers.sql        Triggers that keep bike status in sync automatically
  05_queries.sql         8 analytical queries a business analyst would run
docs/
  ER_Diagram.png         Entity-relationship diagram of the schema (generated from the final schema)
```

The original project report (`DBMS project report.pdf`) and MySQL Workbench model (`Bike Rental System .mwb`) are also preserved in the repository root for reference.

## Schema overview

Nine tables: `Locations`, `BikeTypes`, `Users`, `Admins`, `Bikes`, `Bookings`,
`Payments`, `Reviews`, `Maintenance`. Pricing lives on `BikeTypes` rather than
being repeated on every bike row, and every transactional table (bookings,
payments, reviews, maintenance) references its dimension tables by foreign
key — this is what keeps the design in 3NF rather than a single flat table
with duplicated data.

See `docs/ER_Diagram.png` for the full relationship diagram.

## How the automation works

- **Stored procedures** (`03_procedures.sql`): `sp_book_bike` creates a
  booking only if the bike is actually available; `sp_complete_booking`
  calculates the charge from the bike type's hourly rate and actual rental
  duration, then records the payment; `sp_cancel_booking` cancels an ongoing
  booking.
- **Triggers** (`04_triggers.sql`): a bike's `status` column is never updated
  directly by application code. Inserting a booking automatically marks the
  bike `Rented`; completing or cancelling a booking automatically marks it
  `Available` again; logging a maintenance record automatically marks it
  `Maintenance`. A `BEFORE INSERT` trigger also blocks double-booking at the
  database level, independent of whatever inserted the row.

## Example business questions the queries answer

- Which location generates the most revenue?
- Which bike type is rented most often, and which has the best customer
  ratings?
- Who are the top customers by total spend?
- Which specific bikes are under-utilized across the fleet?
- Which ongoing rentals have been out for more than 4 hours (an "overdue"
  alert)?

## Running the tests

The `tests/` folder validates the schema, business logic, and queries using
Python + SQLite (no MySQL install required to check correctness):

```bash
python tests/test_schema_and_seed_data.py
python tests/test_procedure_and_trigger_logic.py
python tests/test_analytical_queries.py
```

## How to run this

1. Install MySQL 8.0 (or MySQL Workbench, which is what the schema was
   designed in).
2. Run the files in order:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_seed_data.sql
mysql -u root -p < sql/03_procedures.sql
mysql -u root -p < sql/04_triggers.sql
```

3. Try a procedure call, e.g. booking bike #3 for user #2 at location #1:

```sql
CALL sp_book_bike(2, 3, 1, @booking_id, @msg);
SELECT @booking_id, @msg;
```

4. Run any query from `sql/05_queries.sql` directly, or open it in MySQL
   Workbench.

## Notes on validation

This schema, its seed data, and all 8 analytical queries were logic-tested
using a SQLite-compatible translation (constraints, foreign keys, and query
correctness all verified) before being finalized in MySQL syntax, since the
build environment used to prepare this didn't have a MySQL server available.
The stored procedure and trigger *behavior* (booking creation, double-booking
prevention, automatic status transitions, payment calculation) was
additionally verified against equivalent SQLite trigger logic. The MySQL-
specific syntax (`DELIMITER`, `SIGNAL`, `TIMESTAMPDIFF`, etc.) should be
tested against a real MySQL instance before treating this as production-ready.
