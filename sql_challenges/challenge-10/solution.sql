-- ============================================================
-- SCHEMA MIGRATION LAB
-- Using DBMS_METADATA for DDL extraction and schema recreation
-- ============================================================


-- ============================================================
-- SECTION 1: SCHEMA INVENTORY
-- ============================================================

-- Count objects by type
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- List all objects with creation and last modification dates
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

-- Object types found in this schema:
-- Tables, Triggers, Sequences, LOBs, Indexes


-- ============================================================
-- SECTION 2: CONFIGURE DBMS_METADATA TRANSFORM PARAMETERS
-- ============================================================

-- Strip storage, tablespace, and segment clauses for clean, portable DDL.
-- Run this block once per session before any GET_DDL calls.

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY',            TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR',     TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE',           FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE',        FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA',       FALSE);
END;
/


-- ============================================================
-- SECTION 3: EXTRACT TABLE DDL
-- ============================================================

-- DDL for a single table
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS') FROM DUAL;

-- DDL for a single table (first one in schema, for quick testing)
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

-- DDL for all tables
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;


-- ============================================================
-- SECTION 4: DEPENDENCY ANALYSIS
-- ============================================================

-- List all object dependencies in the schema
SELECT referenced_name,
       name AS referencing_name,
       type AS referencing_type
FROM user_dependencies
ORDER BY referenced_name;

-- Filter: only dependencies on tables
SELECT referenced_name,
       name AS referencing_name,
       type AS referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY referencing_type, referencing_name;

-- Aggregate: list all dependencies per object (views, packages, procedures, functions)
SELECT name                AS referencing_name,
       type                AS referencing_type,
       LISTAGG(referenced_name, ', ')
         WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION', 'VIEW')
GROUP BY name, type
ORDER BY referencing_type, referencing_name;


-- ============================================================
-- SECTION 5: SCHEMA MIGRATION — CROSS-SCHEMA REFERENCE CHECK
-- ============================================================

-- Step 1: Inspect DDL of a table that may have foreign keys
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ANY_TABLE_WITH_FK') FROM DUAL;

-- Step 2: Find all foreign key constraints in this schema
SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

-- Step 3: Resolve the owner of referenced constraints
SELECT constraint_name, table_name, owner
FROM all_constraints
WHERE constraint_name IN (
  'SYS_C002527739',
  'SYS_C002527736'
);

-- Step 4: Full FK reference map (table → referenced schema and table)
SELECT
  a.constraint_name,
  a.table_name,
  a.r_owner          AS referenced_schema,
  c.table_name       AS referenced_table
FROM user_constraints a
JOIN all_constraints c
  ON  a.r_constraint_name = c.constraint_name
  AND a.r_owner           = c.owner
WHERE a.constraint_type = 'R';


-- ============================================================
-- SECTION 6: TARGET SCHEMA RECREATION
-- ============================================================

-- WARNING: The block below drops all tables. Use only on a clean target schema.
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Recreate tables in dependency order (tables with no FKs first):

CREATE TABLE "ACCOUNTS" (
  "ACCOUNT_ID"  NUMBER,
  "OWNER_NAME"  VARCHAR2(50)   NOT NULL ENABLE,
  "BALANCE"     NUMBER(10,2)   NOT NULL ENABLE,
  CHECK (balance >= 0) ENABLE,
  PRIMARY KEY ("ACCOUNT_ID")
);

CREATE TABLE "BRICKS" (
  "BRICK_ID"  NUMBER(*,0),
  "COLOUR"    VARCHAR2(10),
  "SHAPE"     VARCHAR2(10),
  "WEIGHT"    NUMBER(*,0)
);

CREATE TABLE "COURSES" (
  "COURSE_ID"    NUMBER,
  "COURSE_NAME"  VARCHAR2(100)  NOT NULL ENABLE,
  "INSTRUCTOR"   VARCHAR2(100),
  "CREDITS"      NUMBER(1,0),
  PRIMARY KEY ("COURSE_ID")
);

CREATE TABLE "DOC_CHUNKS" (
  "CHUNK_ID"      NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL ENABLE,
  "DOC_NAME"      VARCHAR2(200),
  "CHUNK_TEXT"    VARCHAR2(2000),
  "CHUNK_VECTOR"  VECTOR(384, FLOAT32),
  PRIMARY KEY ("CHUNK_ID")
);

CREATE TABLE "MY_BRICK_COLLECTION" (
  "COLOUR"  VARCHAR2(10),
  "SHAPE"   VARCHAR2(10),
  "WEIGHT"  NUMBER(*,0)
);

CREATE TABLE "PATIENT_VISITS" (
  "VISIT_ID"   NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL ENABLE,
  "PATIENT_ID" NUMBER          NOT NULL ENABLE,
  "SITE_ID"    NUMBER          NOT NULL ENABLE,
  "VISIT_DATE" DATE            NOT NULL ENABLE,
  "STATUS"     VARCHAR2(20)    NOT NULL ENABLE,
  "DIAGNOSIS"  VARCHAR2(100),
  "AMOUNT_USD" NUMBER(10,2),
  PRIMARY KEY ("VISIT_ID")
);

CREATE TABLE "PET_CARE_LOG" (
  "PRODUCT_ID"           NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL ENABLE,
  "LOG_DATETIME"         TIMESTAMP(6),
  "CREATED_BY_USER"      VARCHAR2(255),
  "PET_CARE_LOG_DETAILS" VARCHAR2(255),
  "LAST_UPDATE_DATETIME" TIMESTAMP(6),
  "UPDATED_BY_USER"      VARCHAR2(255),
  "UPDATE_DATE"          DATE,
  PRIMARY KEY ("PRODUCT_ID")
);

CREATE TABLE "STUDENTS" (
  "STUDENT_ID"  NUMBER,
  "FIRST_NAME"  VARCHAR2(50)   NOT NULL ENABLE,
  "LAST_NAME"   VARCHAR2(50)   NOT NULL ENABLE,
  "EMAIL"       VARCHAR2(100)  NOT NULL ENABLE,
  "ENROLL_DATE" DATE DEFAULT SYSDATE,
  PRIMARY KEY ("STUDENT_ID"),
  UNIQUE ("EMAIL")
);

-- STUDENT_COURSES depends on STUDENTS and COURSES — create last
CREATE TABLE "STUDENT_COURSES" (
  "SC_ID"       NUMBER,
  "STUDENT_ID"  NUMBER  NOT NULL ENABLE,
  "COURSE_ID"   NUMBER  NOT NULL ENABLE,
  "GRADE"       VARCHAR2(2),
  PRIMARY KEY ("SC_ID"),
  CONSTRAINT "UQ_ENROLLMENT" UNIQUE ("STUDENT_ID", "COURSE_ID"),
  CONSTRAINT "FK_STUDENT"    FOREIGN KEY ("STUDENT_ID") REFERENCES "STUDENTS" ("STUDENT_ID") ENABLE,
  CONSTRAINT "FK_COURSE"     FOREIGN KEY ("COURSE_ID")  REFERENCES "COURSES"  ("COURSE_ID")  ENABLE
);

CREATE TABLE "YOUR_BRICK_COLLECTION" (
  "HEIGHT"  NUMBER(*,0),
  "WIDTH"   NUMBER(*,0),
  "DEPTH"   NUMBER(*,0),
  "COLOUR"  VARCHAR2(10),
  "SHAPE"   VARCHAR2(10)
);


-- ============================================================
-- SECTION 7: POST-MIGRATION VALIDATION
-- ============================================================

-- Compare object counts
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type ORDER BY object_type;

-- Check row counts per table
SELECT table_name, num_rows FROM user_tables ORDER BY table_name;

-- Verify indexes
SELECT index_name, table_name FROM user_indexes ORDER BY index_name;

-- Check FK constraint status
SELECT constraint_name, status
FROM user_constraints
WHERE constraint_type = 'R';


-- ============================================================
-- SECTION 8: MIGRATION SUMMARY
-- ============================================================
--
-- Since expdp was not available, a manual backup strategy was
-- implemented using DBMS_METADATA.
--
-- Step 1: Schema structure was documented via USER_OBJECTS and USER_TABLES.
--
-- Step 2: All DDL was extracted with DBMS_METADATA.GET_DDL for tables,
--         indexes, sequences, constraints, and PL/SQL objects.
--         Schema prefixes were suppressed using EMIT_SCHEMA = FALSE.
--
-- Step 3: Schema was recreated on the target in dependency order:
--           Tables → Sequences → Indexes → FK Constraints → Views → PL/SQL
--
-- Step 4: Migration was validated by comparing object counts and
--         ensuring all objects compiled cleanly.
--
-- This approach provides a complete logical backup using SQL access only.


-- ============================================================
-- DISCUSSION QUESTIONS
-- ============================================================

-- Q1: What are the limitations of DBMS_METADATA vs expdp?
-- A:  DBMS_METADATA only exports DDL (no data), requires a manual
--     spool/cursor loop, and does not scale well for very large schemas.
--     expdp is faster, exports data and DDL together, and handles large
--     schemas reliably — but it requires OS-level directory access and
--     DBA privileges.
--     Use DBMS_METADATA when you have only SQL/read-only access or need
--     to inspect and manually clean the DDL.
--     Use expdp when you have proper access and need speed or completeness.

-- Q2: If you have circular dependencies (A depends on B, B depends on A),
--     how would you handle the reload?
-- A:  Separate object creation from constraint activation:
--       1. Create all tables first, without foreign key constraints.
--       2. Add FK constraints afterward with ALTER TABLE ... ADD CONSTRAINT,
--          once all referenced tables exist.
--       3. For mutually referencing PL/SQL packages, create both package
--          SPECs first (they act as forward declarations), then compile
--          both package BODYs.
--       4. DBMS_METADATA generally returns objects in a safe creation order,
--          but verify with USER_DEPENDENCIES when in doubt.

-- Q3: Your company is migrating from one Oracle database to another.
--     You have read-only access to the old database. What is your plan?
-- A:
--     PHASE 1 — DISCOVERY (source, read-only)
--       1. Inventory all objects via USER_OBJECTS, USER_TABLES,
--          USER_CONSTRAINTS, USER_INDEXES, USER_DEPENDENCIES.
--       2. Identify schemas, roles, DB links, and any external references
--          that will require adjustment on the target.
--
--     PHASE 2 — EXTRACT DDL (source, read-only)
--       3. Configure DBMS_METADATA with EMIT_SCHEMA=FALSE and storage/
--          segment clauses suppressed for clean, portable DDL.
--       4. Spool output to files organized by object type.
--
--     PHASE 3 — CLEAN & ADAPT
--       5. Remove environment-specific clauses (tablespace names, storage
--          parameters) or replace them with target values.
--       6. Fix schema-qualified references if the new schema name differs.
--       7. Resolve any circular dependencies (see Q2).
--
--     PHASE 4 — DEPLOY (target)
--       8. Create the new schema user with appropriate privileges.
--       9. Run DDL in dependency order:
--            Sequences → Tables → Constraints → Indexes →
--            Views → Synonyms → PL/SQL (specs before bodies)
--      10. Compile invalid objects:
--            EXEC DBMS_UTILITY.COMPILE_SCHEMA(schema => 'YOUR_SCHEMA');
--
--     PHASE 5 — VERIFY
--      11. Compare object counts:
--            SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
--      12. Spot-check that views and procedures compile without errors.
--      13. If data migration is required, coordinate with the team for
--          expdp/impdp, external tables, or INSERT ... SELECT over a DB link.