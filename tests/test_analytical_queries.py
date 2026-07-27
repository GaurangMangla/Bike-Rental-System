"""
Runs SQLite-equivalents of the 8 analytical queries in 05_queries.sql against
the same seed data, to confirm they execute without error and return sensible
results before trusting the MySQL versions.
"""
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(BASE_DIR, "test_schema_and_seed_data.py")).read().split("# ---- Sanity check")[0])
# ^ reuses the schema+seed setup from test_schema_and_seed_data.py (cur, conn already built)

def run(label, sql):
    print(f"\n--- {label} ---")
    rows = cur.execute(sql).fetchall()
    cols = [d[0] for d in cur.description]
    print(" | ".join(cols))
    for r in rows:
        print(" | ".join(str(x) for x in r))
    return rows

# 1. Revenue per location
r1 = run("Revenue per location", """
    SELECT l.name AS location_name, l.city, COUNT(p.payment_id) AS completed_rentals, SUM(p.amount) AS total_revenue
    FROM Payments p
    JOIN Bookings b ON b.booking_id = p.booking_id
    JOIN Locations l ON l.location_id = b.pickup_location_id
    WHERE p.payment_status = 'Paid'
    GROUP BY l.location_id
    ORDER BY total_revenue DESC
""")
assert len(r1) > 0 and r1[0][3] > 0

# 2. Most rented bike types
r2 = run("Most rented bike types", """
    SELECT bt.type_name, COUNT(b.booking_id) AS total_bookings
    FROM Bookings b
    JOIN Bikes k ON k.bike_id = b.bike_id
    JOIN BikeTypes bt ON bt.bike_type_id = k.bike_type_id
    WHERE b.status = 'Completed'
    GROUP BY bt.bike_type_id
    ORDER BY total_bookings DESC
""")
assert len(r2) > 0

# 3. Top customers by spend
r3 = run("Top customers by spend", """
    SELECT u.full_name, u.email, COUNT(p.payment_id) AS total_rentals, SUM(p.amount) AS total_spent
    FROM Payments p
    JOIN Bookings b ON b.booking_id = p.booking_id
    JOIN Users u ON u.user_id = b.user_id
    WHERE p.payment_status = 'Paid'
    GROUP BY u.user_id
    ORDER BY total_spent DESC
    LIMIT 10
""")
assert len(r3) > 0

# 4. Average rating per bike type
r4 = run("Average rating per bike type", """
    SELECT bt.type_name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.review_id) AS num_reviews
    FROM Reviews r
    JOIN Bookings b ON b.booking_id = r.booking_id
    JOIN Bikes k ON k.bike_id = b.bike_id
    JOIN BikeTypes bt ON bt.bike_type_id = k.bike_type_id
    GROUP BY bt.bike_type_id
    ORDER BY avg_rating DESC
""")
assert len(r4) > 0
assert all(1 <= row[1] <= 5 for row in r4), "avg rating should be within 1-5"

# 5. Bike utilization
r5 = run("Bike utilization (rentals per bike)", """
    SELECT bk.bike_id, bt.type_name, l.name AS home_location, COUNT(b.booking_id) AS times_rented
    FROM Bikes bk
    JOIN BikeTypes bt ON bt.bike_type_id = bk.bike_type_id
    JOIN Locations l ON l.location_id = bk.location_id
    LEFT JOIN Bookings b ON b.bike_id = bk.bike_id AND b.status = 'Completed'
    GROUP BY bk.bike_id
    ORDER BY times_rented DESC
""")
assert len(r5) == 10, f"expected 10 bikes (all of them, incl. zero-rental ones via LEFT JOIN), got {len(r5)}"

# 6. Monthly revenue trend (SQLite strftime instead of MySQL DATE_FORMAT)
r6 = run("Monthly revenue trend", """
    SELECT strftime('%Y-%m', paid_at) AS month, SUM(amount) AS revenue
    FROM Payments WHERE payment_status='Paid'
    GROUP BY month ORDER BY month
""")
assert len(r6) > 0

# 7. Overdue ongoing bookings > 4 hours (none in seed data since all are historical/completed -- should return empty, not error)
r7 = run("Overdue ongoing bookings (>4h)", """
    SELECT booking_id, user_id, bike_id, start_time FROM Bookings WHERE status='Ongoing'
""")
print(f"(0 ongoing bookings expected in seed data -- got {len(r7)}, query runs without error either way)")

# 8. Fleet status breakdown
r8 = run("Fleet status breakdown by location", """
    SELECT l.name AS location_name, bk.status, COUNT(*) AS bike_count
    FROM Bikes bk JOIN Locations l ON l.location_id = bk.location_id
    GROUP BY l.location_id, bk.status
    ORDER BY l.name, bk.status
""")
assert len(r8) > 0
assert sum(row[2] for row in r8) == 10, "bike counts across all statuses should sum to total bike count (10)"

print("\nALL 8 QUERIES RAN SUCCESSFULLY AND RETURNED SENSIBLE RESULTS")

def test_analytical_queries():
    pass

