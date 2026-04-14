# Database Indexing: Comprehensive Notes

## 1. What is an Index?
An index is a physical structure that the database engine uses to locate rows without scanning the entire table. It is essentially a map that associates a **column value** with the **RowID** (physical address) of the data on the disk.

---

## 2. B-Tree Indexes (Balanced Tree)
The B-Tree is the default and most common index type in relational databases (Oracle, MySQL, PostgreSQL, SQL Server).

### How it Works:
* **Root Node:** The entry point of the index.
* **Branch Nodes:** Contain ranges (e.g., A–M, N–Z) to direct the search path.
* **Leaf Nodes:** The bottom layer. These contain the actual indexed values and the pointer (RowID) to the table.

### Key Characteristics:
* **Balanced:** The distance from the root to any leaf is always the same, ensuring predictable performance ($O(\log n)$).
* **Sorted:** Data is kept in order, making it excellent for **Range Scans** (`BETWEEN`, `>`, `<`) and `ORDER BY` operations.
* **High Cardinality:** Works best when values are unique or have very few duplicates.



---

## 3. Hash Indexes
Hash indexes use a "Hash Function" to map a column's value to a specific "bucket" in the index.

### How it Works:
1. The database applies a mathematical formula (hash) to the input value (e.g., `patient_id = 1234`).
2. The formula outputs a specific location (bucket).
3. The database jumps directly to that bucket to find the RowID.

### Key Characteristics:
* **Equality Only:** Hash indexes are lightning-fast for exact match (`=`) queries ($O(1)$ complexity).
* **No Ranges:** Because hashing "scrambles" the data randomly, you **cannot** use a hash index for `BETWEEN`, `>`, or `<` queries. 
* **No Sorting:** You cannot use a hash index to optimize an `ORDER BY` clause.



---

## 4. Cardinality & Selectivity
These concepts determine if the Database Optimizer will actually use your index.

* **High Cardinality:** A column with many unique values (e.g., Social Security Number, Email). 
  * *Result:* High Selectivity. The index narrows the search down to 1 or 2 rows. **Great for indexing.**
* **Low Cardinality:** A column with many repeating values (e.g., Gender, Status, SiteID 1-5).
  * *Result:* Low Selectivity. The index would return 20% or more of the table. **Usually ignored by the Optimizer** in favor of a Full Table Scan.

---

## 5. Composite Indexes (Multi-Column)
An index built on more than one column, e.g., `(last_name, first_name)`.

### The Left-Prefix Rule (Leading Column Rule):
The order of columns strictly dictates how the index can be used. An index on `(A, B)` can be used for:
* `WHERE A = ...`
* `WHERE A = ... AND B = ...`

It **cannot** (usually) be used for:
* `WHERE B = ...` (Because the data is physically sorted by column A first, making a search on B alone inefficient).



---

## 6. SARGability (Search Argument-able)
To use an index, the column in the `WHERE` clause must be "naked" (unmodified by functions or math). 

* **Non-SARGable (Breaks Index):** * `WHERE TO_CHAR(id) = '123'`
  * `WHERE price * 1.1 > 100`
* **SARGable (Uses Index):** * `WHERE id = 123`
  * `WHERE price > 100 / 1.1`

---

## 7. The Performance Trade-off (DML Overhead)
While indexes speed up **Read** operations (`SELECT`), they slow down **Write** operations (`INSERT`, `UPDATE`, `DELETE`).
* Every time a row is added or modified, the database must also update every index attached to that table.
* **Rule of Thumb:** Only index columns that are frequently used in `WHERE`, `JOIN`, or `ORDER BY` clauses. Do not over-index high-transaction (OLTP) tables.