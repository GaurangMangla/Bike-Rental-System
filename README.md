# 🚲 Bike Rental System - DBMS Project

This repository contains the SQL implementation and database design for a **Bike Rental System** developed as part of an academic DBMS project. The project demonstrates database normalization, entity-relationship modeling, and efficient SQL queries to manage users, bikes, bookings, payments, and administrative operations.

## 📚 Project Overview

The Bike Rental System is designed to help manage:
- User registrations and profiles
- Bike inventory and availability
- Booking and rental transactions
- Payment records and billing
- Location-based bike tracking
- Admin-level control for managing users and bikes

The primary focus of this project is on the **database design and SQL implementation**, which includes DDL, DML, and PL/SQL components.

---

## 🗂️ Contents

- `ER_Diagram.png` – Entity Relationship Diagram of the system
- `Schema.sql` – SQL script for creating and populating the database schema
- `Queries.sql` – Frequently used SQL queries (e.g., availability check, payment summary)
- `Procedures.sql` – Stored procedures and functions used in the system
- `Triggers.sql` – Database triggers for automation
- `Report.pdf` – Full project report (40 pages) with detailed analysis and documentation
- `README.md` – Project overview and usage guide

---

## 🧠 Key Features

- **Normalized Database** (up to 3NF) for efficiency and minimal redundancy
- **Secure and Logical Structure** for handling real-world rental operations
- **Stored Procedures** to automate common operations (e.g., booking a bike)
- **Triggers** to maintain data integrity (e.g., stock update after booking)
- **Sample Queries** for analytics and insights (e.g., most rented bikes, revenue per location)

---

## 🧱 Database Tables

The project includes the following main tables:

- `User` – Stores customer information
- `Admin` – Stores admin credentials
- `Bike` – Stores bike inventory and availability status
- `Location` – Stores city/location info for bikes
- `Booking` – Stores rental records for users
- `Payment` – Stores payment details for completed bookings

---

## ⚙️ How to Use

1. **Clone this repository**:
   ```bash
   git clone https://github.com/<your-username>/bike-rental-dbms.git
   cd bike-rental-dbms
