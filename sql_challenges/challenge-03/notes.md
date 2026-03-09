## SQL Aggregation Guide

Aggregation functions operate on a column's data across multiple rows to return a single, summarized value. To use them, place the column name or expression inside the parentheses (e.g., `SUM(order_total)`).

### 1. Common Aggregate Operations

| Function | Description |
| :--- | :--- |
| **`SUM()`** | The result of adding up all the non-null values in the group. |
| **`MIN()`** | The smallest value in the group. |
| **`MAX()`** | The largest value in the group. |
| **`AVG()`** | The arithmetic mean of all the non-null values in the group. |
| **`MEDIAN()`** | The middle value in the data set. |
| **`STDDEV()`** | The standard deviation of the values. |
| **`VARIANCE()`**| The statistical variance of the values. |
| **`STATS_MODE()`**| The most common (frequent) value in the group. |

> **Mathematical Note:** `CEIL()` (round up a number) is often used alongside these, but it is a **scalar function**, not an aggregate. It modifies an individual number rather than grouping rows together.

---

### 2. Grouping & Filtering Data



When you want to calculate aggregates for specific categories rather than the entire table, you use grouping.

* **`GROUP BY`**: Groups the rows depending on matching values in one or more columns. 
* **`HAVING`**: Filters grouped data. If you want to apply a condition to the result of an *aggregate operation*, you must use `HAVING` instead of `WHERE`.

> **The Golden Rule of Grouping:** All unaggregated columns in your `SELECT` clause MUST be included in your `GROUP BY` clause.

---

### 3. Conditional Aggregation

You can place `CASE` statements inside aggregate functions to perform operations only on rows that meet specific criteria. 

**Example 1: Conditional Averages & Percentages**
```sql
SELECT 
    -- Calculates the average total, but only for completed orders
    AVG(CASE 
        WHEN status = 'Completed' THEN order_total 
        ELSE NULL 
    END) AS avg_completed_total,

    -- Calculates the percentage of orders that are completed
    AVG(CASE 
        WHEN status = 'Completed' THEN 1.0 
        ELSE 0.0 
    END) * 100 AS percent_completed

FROM orders;

### Adding conditions to the aggregate operations
SELECT 
    -- Example 1: Conditional Average
    AVG(CASE 
        WHEN status = 'Completed' THEN order_total 
        ELSE NULL 
    END) AS avg_completed_total,

    -- Example 2: Calculating a Percentage
    AVG(CASE 
        WHEN status = 'Completed' THEN 1.0 
        ELSE 0.0 
    END) * 100 AS percent_completed

FROM orders;

SELECT 
    category,
    
    -- Total number of orders in this category
    COUNT(*) as total_orders,
    
    -- Count of only cancelled orders
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    
    -- Sum of revenue for completed orders
    SUM(CASE WHEN status = 'Completed' THEN order_total ELSE 0 END) AS valid_revenue,
    
    -- Highest order value among completed orders
    MAX(CASE WHEN status = 'Completed' THEN order_total ELSE NULL END) AS max_valid_order

FROM orders
GROUP BY category;
```sql

* **`ROLLUP`**:
rollup ( colour, shape )
Calculate -
Totals for each ( colour, shape ) pair
Totals for each colour
The grand total

* **`CUBE`**:
cube ( colour, shape )
You get groupings for-
Each ( colour, shape ) pair
Each colour
Each shape
All the rows in the table