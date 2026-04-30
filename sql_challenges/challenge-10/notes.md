# Schema Management & Migration

## 1. Data Dictionary Views

In this case, Oracle provides built-in read-only views to inspect the current schema without any special privileges.

| View | What it shows |
|---|---|
| `USER_OBJECTS` | All objects owned by the current user (tables, indexes, triggers, etc.) |
| `USER_TABLES` | Tables only, with storage and row count metadata |
| `USER_CONSTRAINTS` | Constraints defined on the user's tables |
| `USER_INDEXES` | Indexes on the user's tables |
| `USER_DEPENDENCIES` | Dependencies between objects in the schema |
| `ALL_CONSTRAINTS` | Constraints visible to the user, including other schemas |

### Key columns in `USER_DEPENDENCIES`

| Column | Meaning |
|---|---|
| `NAME` | The object that depends on something else (the referencing object) |
| `TYPE` | Type of the referencing object (TABLE, VIEW, PACKAGE, etc.) |
| `REFERENCED_NAME` | The object being depended on |
| `REFERENCED_TYPE` | Type of the referenced object |

> **Gotcha:** Columns in `USER_DEPENDENCIES` do NOT use a `REFERENCING_` prefix.
> Aliases (`AS referencing_name`) only work in `ORDER BY`, not in `WHERE` or `GROUP BY`.


---

## 2. SQL Rules — Aliases and Aggregation

### Column alias scope
Oracle resolves `SELECT` aliases only after the `SELECT` clause executes.
This means:

- `ORDER BY` — can use aliases
- `WHERE` — must use original column names
- `GROUP BY` — must use original column names
- `HAVING` — must use original column names

### GROUP BY rule
Every column in `SELECT` that is not inside an aggregate function (`COUNT`, `SUM`, `LISTAGG`, etc.)
must appear in the `GROUP BY` clause. Oracle will throw `ORA-00979` otherwise.

### LISTAGG
Concatenates values from multiple rows into a single string within a group.