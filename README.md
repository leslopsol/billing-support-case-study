# billing-support-case-study
SQL analysis of SaaS invoices: payment failures, disputes, refunds and overdue accounts (PostgreSQL / Supabase)

## About this project

A small case study built to practice the kind of questions a Billing Support team answers every day. The dataset is fictional: 30 invoices from 10 SaaS customers on three plans (Starter, Growth, Business), from August to October 2026.

All queries were written and run in the Supabase SQL Editor. You can find them, with comments, in [`queries.sql`](queries.sql).

## Table: `invoices`

| Column | Type | Description |
|---|---|---|
| invoice_id | text | Invoice ID |
| customer_id | text | Customer ID |
| customer_name | text | Customer name |
| plan | text | Starter, Growth or Business |
| amount_usd | numeric | Invoice amount in USD |
| invoice_date | date | Date the invoice was issued |
| due_date | date | Payment due date |
| status | text | paid, failed, refunded, disputed or overdue |
| reason | text | Reason for a failure, dispute or refund (NULL for paid and overdue invoices) |
| payment_attempts | integer | Number of payment attempts |

## Process

1. **Data cleanup:** the CSV import stored dates and payment attempts as text, and amounts as float. I changed them to `date`, `integer` and `numeric`, since float can cause rounding errors with cents.
2. **Data quality checks:** confirmed that empty reasons are stored as NULL, and that every failed, refunded or disputed invoice has a reason.
3. **Analysis:** five business questions, plus one extra.

## Key findings

**1. Invoices per status**

| Status | Invoices |
|---|---|
| paid | 14 |
| failed | 7 |
| overdue | 4 |
| disputed | 3 |
| refunded | 2 |

16 of 30 invoices (over half) ended up in a status other than paid.

**2. Failed payments by reason**

The 7 failures are spread across four reasons: `authentication_required` (2), `card_declined` (2), `expired_card` (2) and `insufficient_funds` (1). Each reason calls for a different action: asking the customer to update the card, retrying the charge later, or asking the customer to complete authentication with their bank.

**3. Overdue invoices (more than 30 days)**

Two invoices are more than 30 days past due, and both belong to the same customer, **Lumen Forms**, for a total of **$1,295.20**. One of them is over two months overdue.

**4. Disputes and refunds**

- Disputed: **$384.60** (3 invoices)
- Refunded: **$215.05** (2 invoices)

**5. Customers with repeated failed payments**

| Customer | Failed payments |
|---|---|
| Bright Ledger | 3 |
| Atlas Notes | 2 |
| Orbit Kitchen | 2 |

These three customers account for all 7 failed payments. Atlas Notes also has a disputed invoice, so it shows problems on more than one front.

**Extra: paid invoices per month**

| Month | Paid invoices | Total paid |
|---|---|---|
| 2026-08 | 5 | $1,198.30 |
| 2026-09 | 4 | $1,115.50 |
| 2026-10 | 5 | $485.60 |

October had the same number of paid invoices as August, but collected about 60% less. The difference comes from Cedar Stack: its August and September Business invoices were paid, but its October invoice ($870) is still overdue. Since Business invoices are the largest, one unpaid Business invoice has a big impact on the monthly total.

## Suggested next steps

- Follow up with **Lumen Forms** on its two overdue invoices.
- Reach out to Bright Ledger and Atlas Notes, whose October payments also failed: Bright Ledger needs to update its card, and Atlas Notes needs to complete authentication with its bank. Orbit Kitchen’s October payment went through on the second attempt, so its card issue seems resolved.
- Review the **Atlas Notes** account as a whole, since it has both failed payments and a dispute.
- Follow up with Cedar Stack on its October invoice before it passes 30 days overdue.

## Notes and caveats

- **Time zone:** Supabase runs in UTC. When queries run in the evening from UTC-6, `CURRENT_DATE` can already be the next day, so overdue counts may show one extra day.
- **Monthly totals:** the table has no payment date, so the monthly view groups by invoice month, not by the month the money was received.

## Skills used

`SELECT`, `WHERE`, `AND`, `IN`, `NOT IN`, `IS NULL`, `COUNT`, `SUM`, `GROUP BY`, `HAVING`, `ORDER BY`, aliases, date arithmetic with `CURRENT_DATE`, `TO_CHAR`, and `ALTER TABLE` for data type cleanup.
