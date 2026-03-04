# SQL Window Functions Quick Reference

## The `OVER` Clause
The `OVER` clause defines the window (set of rows) that the function will operate on.

* **`OVER ()`**: Applies the function to the entire result set (the full table).
* **`OVER (PARTITION BY ...)`**: Acts like a `GROUP BY` for the window, dividing the result set into distinct partitions.
* **`OVER (ORDER BY ...)`**: Defines the logical order of rows within a partition. It is frequently used for calculating cumulative sums or running totals.
* **`OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`**: Defines a specific window frame, allowing you to select exactly which surrounding rows to aggregate relative to the current row.

---

## Ranking Functions
These functions assign a sequential integer to each row within a partition.

* **`ROW_NUMBER()`**: Enumerates rows with a unique sequential integer (1, 2, 3...).
* **`RANK()`**: Assigns a rank to each row. If there is a tie, rows get the same rank, and the next rank number is skipped (e.g., 1, 2, 2, 4).
* **`DENSE_RANK()`**: Assigns a rank to each row. If there is a tie, rows get the same rank, but it does *not* skip the next rank number (e.g., 1, 2, 2, 3).

---

## Practical Example: Filtering with a Subquery
Because window functions are evaluated *after* the `WHERE` clause in standard SQL execution order, you cannot filter by them directly. You must wrap them in a subquery or CTE.

```sql
SELECT * FROM (
    SELECT 
        name, 
        salary, 
        department_id, 
        MAX(salary) OVER(PARTITION BY department_id) AS max_salary 
    FROM employee
) e
WHERE e.salary = e.max_salary;