#Notes.

Offset helps to declare where we should start counting (skip first to elements means offset 2)

NOT LIKE is for insensitive case, cake is sensitive. Adding % is that there can be more chars in the place where you add %. 

# SQLBolt Fundamentals: Lessons 1-5

The first few lessons of SQLBolt focus heavily on the fundamentals of retrieving and filtering data from a single table. They are designed to give you a solid foundation in constructing basic queries.

## 1. Basic Data Retrieval (`SELECT` & `FROM`)
* **Selecting Specific Columns:** Learning how to query only the specific pieces of data you need from a table (e.g., `SELECT title, director FROM movies;`).
* **Selecting All Columns:** Using the asterisk wildcard (`*`) to grab every column in a table (e.g., `SELECT * FROM movies;`).

## 2. Filtering with Basic Constraints (`WHERE` Part 1)
* **The `WHERE` Clause:** Introducing the concept of filtering rows based on specific conditions.
* **Standard Operators:** Using mathematical comparison operators to filter numerical or string data:
    * Equal to (`=`) and Not equal to (`!=` or `<>`)
    * Greater than (`>`), Less than (`<`)
    * Greater than or equal to (`>=`), Less than or equal to (`<=`)

## 3. Filtering with Advanced Constraints (`WHERE` Part 2)
* **Logical Operators:** Combining multiple conditions using `AND` and `OR`.
* **Range and List Matching:**
    * `BETWEEN … AND …`: Finding values within a specific numerical or alphabetical range.
    * `IN (...)`: Checking if a value matches any value in a specified list.
* **Pattern Matching:**
    * `LIKE`: Using the `%` wildcard to perform case-insensitive string matching (e.g., `LIKE '%Batman%'` to find any title containing the word Batman).

## 4. Sorting and Paginating Results
* **Sorting Data (`ORDER BY`):** Organizing your query results alphabetically or numerically. You learn to sort in both ascending (`ASC`) and descending (`DESC`) order.
* **Restricting Rows (`LIMIT`):** Capping the number of rows returned by your query (very useful for "Top 10" lists).
* **Skipping Rows (`OFFSET`):** Telling the database where to start returning rows from, which is the foundational concept for building pagination in apps.

## 5. Review and Consolidation
* **Putting It All Together:** The final lesson in this introductory block is a comprehensive review.
* **Execution Order:** It forces you to combine `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`, and `OFFSET` all in the same query to ensure you understand the correct syntax and execution order.