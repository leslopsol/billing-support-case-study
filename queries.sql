/*
  Billing Support Case Study
  SQL analysis of a fictional SaaS invoices table:
  30 invoices, 10 customers, August to October 2026.
  Database: Supabase (PostgreSQL), SQL Editor.
*/


-- SETUP
-- Data cleanup: the CSV import stored dates and payment attempts as text, and amounts as float.
-- Changed them to the correct data types: date for date calculations, integer for counts,
-- and numeric for money, since float can cause rounding errors with cents.

-- amount_usd was changed to numeric in the Supabase Table Editor.
-- This is the equivalent SQL, so the setup can be reproduced:
ALTER TABLE invoices
ALTER COLUMN amount_usd TYPE numeric USING amount_usd::numeric;

ALTER TABLE invoices
ALTER COLUMN invoice_date TYPE date USING invoice_date::date,
ALTER COLUMN due_date TYPE date USING due_date::date,
ALTER COLUMN payment_attempts TYPE integer USING payment_attempts::integer;


-- DATA QUALITY CHECK 1
-- Checked whether empty reasons were stored as NULL or as empty text.

SELECT invoice_id, status, reason
FROM invoices
WHERE reason IS NULL;


-- DATA QUALITY CHECK 2
-- Confirmed that every failed, refunded or disputed invoice has a reason.
-- Expected result: 0 rows.

SELECT invoice_id, status, reason
FROM invoices
WHERE reason IS NULL
AND status NOT IN ('paid', 'overdue');


-- Q1: How many invoices are there per status?
-- Quick overview of billing health across all invoices.

SELECT status, COUNT(*) AS total_invoices
FROM invoices
GROUP BY status
ORDER BY total_invoices DESC;


-- Q2: How many payments failed for each reason?

SELECT reason, COUNT(*) AS failed_payments
FROM invoices
WHERE status = 'failed'
GROUP BY reason
ORDER BY failed_payments DESC;


-- Q3: Which overdue invoices are more than 30 days past due?
-- Note: Supabase runs in UTC. When working in the evening from UTC-6, CURRENT_DATE
-- can already be the next day, so days_overdue may show one extra day.

SELECT invoice_id, customer_name, amount_usd, due_date, CURRENT_DATE - due_date AS days_overdue
FROM invoices
WHERE status = 'overdue' AND CURRENT_DATE - due_date > 30
ORDER BY days_overdue DESC;


-- Q4: What is the total amount in disputes and in refunds?

SELECT status, SUM(amount_usd) AS total_usd
FROM invoices
WHERE status IN ('disputed', 'refunded')
GROUP BY status
ORDER BY total_usd DESC;


-- Q5: Which customers have 2 or more failed payments?
-- Used as an early indicator of churn risk.

SELECT customer_id, customer_name, COUNT(*) AS total_failed_payments
FROM invoices
WHERE status = 'failed'
GROUP BY customer_id, customer_name
HAVING COUNT(*) >= 2
ORDER BY total_failed_payments DESC;


-- EXTRA: Total collected (paid) per month, to compare trends over time.
-- Caveat: the table has no payment date, so this groups by invoice month,
-- not by the month the money was actually received.

SELECT TO_CHAR(invoice_date, 'YYYY-MM') AS month, COUNT(*) AS paid_invoices, SUM(amount_usd) AS total_paid
FROM invoices
WHERE status = 'paid'
GROUP BY month
ORDER BY month ASC;


-- FOLLOW-UP: Payment history of the customers with repeated failed payments.
-- Used to check which customers still had a failed payment in October.

SELECT customer_name, invoice_date, status, reason, payment_attempts
FROM invoices
WHERE customer_name IN ('Bright Ledger', 'Atlas Notes', 'Orbit Kitchen')
ORDER BY customer_name, invoice_date;
