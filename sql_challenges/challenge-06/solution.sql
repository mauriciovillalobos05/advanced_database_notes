CREATE TABLE PET_CARE_LOG (
  PRODUCT_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  LOG_DATETIME timestamp,
  CREATED_BY_USER varchar(255),
  PET_CARE_LOG_DETAILS varchar(255), 
  LAST_UPDATE_DATETIME timestamp,
  UPDATED_BY_USER varchar(255),
  UPDATE_DATE date
);

CREATE OR REPLACE TRIGGER PET_CARE_LOG_INSERT
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- 1. Assign current timestamp to UPDATE_DATE
    :NEW.UPDATE_DATE := SYSTIMESTAMP;

    -- 2. Assign the current user (using the USER pseudocolumn)
    :NEW.UPDATED_BY_USER := USER;

    -- 3. Check if CREATED_BY_USER is provided
    IF :NEW.CREATED_BY_USER IS NULL OR TRIM(:NEW.CREATED_BY_USER) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'User must be provided for the CREATED_BY_USER field.');
    END IF;

EXCEPTION
    -- 4. Handle all errors in one general exception handler
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An unexpected error occurred in the trigger: ' || SQLERRM);
END;

CREATE OR REPLACE TRIGGER PET_CARE_LOG_UPDATE
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- 1. Compare current database user with the existing UPDATED_BY_USER
    IF USER != :OLD.UPDATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20003, 'Update failed: Current user does not match the last user who updated this record.');
    END IF;

    -- 2. If the check passes, we update the timestamp automatically
    :NEW.UPDATE_DATE := SYSTIMESTAMP;
    :NEW.LAST_UPDATE_DATETIME := SYSTIMESTAMP;

EXCEPTION
    -- 3. General exception handler as requested
    WHEN OTHERS THEN
        IF SQLCODE = -20003 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'An unexpected error occurred: ' || SQLERRM);
        END IF;
END;

CREATE OR REPLACE TRIGGER PET_CARE_LOG_DELETE
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- 1. Compare current database user with 'JOEMANAGER'
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20003, 'DELETE failed: Current user does not match the user with permission to delete data.');
    END IF;

EXCEPTION
    -- 2. General exception handler as requested
    WHEN OTHERS THEN
        IF SQLCODE = -20003 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'An unexpected error occurred: ' || SQLERRM);
        END IF;
END;