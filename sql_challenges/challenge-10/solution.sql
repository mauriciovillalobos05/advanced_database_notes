-- List all the objects in your schema using user_objects
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- Group by object_type and count them
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

-- Which object types do you have?
--Tables, Triggers, Sequences, Lobs, Indexes

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- First, set transform params for clean output:
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Get DDL for one of your tables (replace MY_TABLE with actual name)
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS') FROM DUAL;

-- Or get all tables at once:
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;


Oracle Logo
FreeSQL

Worksheet

Library

23ai

Connect to the Database

Help and Feedback

Sign Out
 
Navigator
Files
11 or more matches found
My Schema
Tables
Search objects

Received data for node: worksheet-object-navigator-tree


[ SQL Worksheet ]*

Run Statement (Ctrl+Enter, ⌘+Enter)

Run Script (F5)

Explain Plan (F10)

Download Editor Content (Ctrl+I, ⌘+I)

Format (F7)

Convert Case (Ctrl+B, ⌘+B)

Clear (Ctrl+D, ⌘+D)


Start tour
1234
-- Or get all tables at once:
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;

-- Identify the key parts in the output:
CREATE TABLE "A01644972_SCHEMA_HCVFZ"."MY_BRICK_COLLECTION" 
(	"COLOUR" VARCHAR2(10), 
"SHAPE" VARCHAR2(10), 
"WEIGHT" NUMBER(*,0)
) SEGMENT CREATION IMMEDIATE 
PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
NOCOMPRESS LOGGING
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "USERS" 


SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

--
CREATE TABLE "A01644972_SCHEMA_HCVFZ"."ACCOUNTS" 
(	"ACCOUNT_ID" NUMBER, 
"OWNER_NAME" VARCHAR2(50) NOT NULL ENABLE, 
"BALANCE" NUMBER(10,2) NOT NULL ENABLE, 
    CHECK (balance >= 0) ENABLE, 
    PRIMARY KEY ("ACCOUNT_ID")
USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "USERS"  ENABLE
) SEGMENT CREATION IMMEDIATE 
PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
NOCOMPRESS LOGGING
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
TABLESPACE "USERS" 

-- Scenario: Migrating from SCHEMA_OLD to SCHEMA_NEW

-- 1. First, identify schema names embedded in your DDL:
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE table_name = 'ANY_TABLE_WITH_FK';

-- 2. Check for schema-qualified references:
SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

-- 3.
SELECT constraint_name, table_name, owner
FROM all_constraints
WHERE constraint_name IN (
    'SYS_C002527739',
    'SYS_C002527736'
);

-- 4.
SELECT 
    a.constraint_name,
    a.table_name,
    a.r_owner AS referenced_schema,
    c.table_name AS referenced_table
FROM user_constraints a
JOIN all_constraints c
    ON a.r_constraint_name = c.constraint_name
    AND a.r_owner = c.owner
WHERE a.constraint_type = 'R';