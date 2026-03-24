# Database Triggers: Core Concepts and Implementation

A **Database Trigger** is a stored PL/SQL block that "fires" (executes) automatically when a specific event occurs in the database. Unlike stored procedures, which must be called explicitly, triggers are event-driven.

---

## 1. The Trigger Architecture (E-C-A)
Triggers typically follow the **Event-Condition-Action** model:
* **Event:** The DML statement (`INSERT`, `UPDATE`, `DELETE`) or DDL statement that triggers the code.
* **Condition:** An optional `WHEN` clause that restricts the trigger to fire only if certain criteria are met.
* **Action:** The procedural code (PL/SQL) that executes.

---

## 2. Trigger Timing & Level
Understanding *when* and *how often* a trigger runs is critical for performance and logic.

### Timing
| Timing | Description | Best Use Case |
| :--- | :--- | :--- |
| **BEFORE** | Executes before the triggering statement is applied to the table. | Validating data or derived column values. |
| **AFTER** | Executes after the statement is committed to the table. | Auditing, logging, or updating related tables. |
| **INSTEAD OF** | Executes *instead of* the triggering statement. | Making non-updatable Views modifiable. |

### Level
* **Statement-Level:** Fires once for the entire SQL statement. (Default)
* **Row-Level:** Fires once for **every individual row** affected. Defined by the `FOR EACH ROW` clause.

---

## 3. Correlation Identifiers
In **Row-Level** triggers, you can access the data state using pseudo-records:

* **`:OLD`**: Refers to the column values *before* the operation.
    * `INSERT`: All values are `NULL`.
    * `UPDATE`: Contains the original values.
    * `DELETE`: Contains the values being removed.
* **`:NEW`**: Refers to the column values *after* the operation.
    * `INSERT`: Contains the values being added.
    * `UPDATE`: Contains the new, proposed values.
    * `DELETE`: All values are `NULL`.

---

## 4. Common Implementation Patterns

### Automatic Auditing
Automatically tracking who changed a record and when.
```sql
:NEW.UPDATE_DATE := SYSTIMESTAMP;
:NEW.UPDATED_BY_USER := USER;