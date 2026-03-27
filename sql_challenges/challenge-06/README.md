# House-o-Pets Database Automation Requirements

To improve and automate the House-o-Pets database system, three specific triggers will be implemented on the `PET_CARE_LOG` table. These triggers handle automated data entry, row-level security for updates, and restricted deletion permissions.

---

## 1. Insert Trigger: Audit Automation
**Trigger Name:** `PET_CARE_LOG_INSERT`

### Objectives:
* **Timing:** Fires `BEFORE INSERT` for each row.
* **Automation:** * Assigns the current system date and time to the `UPDATE_DATE` column.
    * Assigns the current database `USER` to the `UPDATED_BY_USER` column using pseudocolumns.
* **Error Handling:** * Includes a general exception handler (`WHEN OTHERS`).
    * Returns custom error messages via the `RAISE_APPLICATION_ERROR` procedure.

---

## 2. Update Trigger: Ownership Validation
**Trigger Name:** `PET_CARE_LOG_UPDATE`

### Objectives:
* **Timing:** Fires `BEFORE UPDATE` for each row.
* **Security Logic:** * Compares the current session `USER` with the existing value in the `UPDATED_BY_USER` column (`:OLD.UPDATED_BY_USER`).
    * **Success:** If the users match, the update proceeds and the timestamp is refreshed.
    * **Failure:** If the users do not match, the trigger raises an exception to block the update.
* **Error Handling:** * Implements a general exception handler consistent with the Insert trigger logic.

---

## 3. Delete Trigger: Managerial Restriction
**Trigger Name:** `PET_CARE_LOG_DELETE`

### Objectives:
* **Timing:** Fires `BEFORE DELETE` for each row.
* **Access Control:** * Checks the session `USER` attempting the deletion.
    * **Authorized:** Only the user **'JOEMANAGER'** is permitted to delete records.
    * **Unauthorized:** Any other user attempting a delete will face a forced failure and an error message, regardless of whether they created the record.
* **Error Handling:** * Implements a general exception handler to catch and report database errors.

---

## Schema Reference
The implementation of these triggers relies on the structure defined in the **Pet Store Schema**, specifically targeting the audit and log fields within the `PET_CARE_LOG` entity.
https://www.relationaldbdesign.com/programming-plsql/module1/database-pet-store-schema.php