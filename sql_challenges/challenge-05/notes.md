### SQL Set Operators Summary

| Operator | Description | Includes Duplicates? |
| :--- | :--- | :--- |
| **UNION** | Returns results from both queries. | No |
| **UNION ALL** | Returns results from both queries. | Yes |
| **MINUS** * | Returns the result of one query excluding the other query and the intersection. | No |
| **INTERSECTION** | Returns the common elements shared by both queries. | No |

*\*Note: In many SQL databases (like PostgreSQL and SQL Server), `MINUS` is written as `EXCEPT`.*

---

### Detailed Breakdown

#### 1. UNION

Combines the result sets of two or more queries into a single column. It automatically **removes duplicate rows** from the final result.

#### 2. UNION ALL
Operates exactly like `UNION`, but it **keeps all duplicate rows**. Because it doesn't have to spend processing power searching for and removing duplicates, it runs faster than a standard `UNION`.

#### 3. MINUS (or EXCEPT)

Compares two queries and returns only the distinct rows from the **first** query that do not appear in the second query. 

#### 4. INTERSECTION (or INTERSECT)

Compares two queries and returns only the **common elements**—meaning the exact rows that are output by both the first and the second query.