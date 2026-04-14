SELECT * FROM patient_visits WHERE site_id = 3; -- not using an index, Execution time: 0.023 seconds

-- a) What scan type do you see? Why?
-- a full scan, because there is no index created for site_id (because it is not a PK).
-- b) site_id has values 1–5. Is this high or low cardinality?
-- low cardinality
-- c) Would adding an index on site_id help? Why or why not?
-- no, we have few values so the index would only contain 5 nodes, it is not worth indexing.


CREATE INDEX index_visit_date ON patient_visits (visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- Questions:
-- a) Does Oracle use the index for this range?
-- no, it is doing a full scan
-- b) Change the range to the last 7 days. Does the plan change?
-- no, it is doing a full scan.
-- c) Change to the last 700 days. What happens?
-- not using an index.
-- d) Why does the range size affect whether Oracle uses the index?
-- the optimizer determines if it would return a small section of the table, so it decides if it is worth using the index.


CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- Questions:
-- a) Does the plan use the composite index?
-- yes
-- b) Now try querying ONLY on visit_date (no patient_id).
--    Does the composite index get used? Why not?
-- No, since the other column is first, the index will not be used.
-- c) What's the rule about column order in composite indexes?
-- Left-Prefix Rule Your index is sorted by patient_id first. Since your WHERE clause only mentions visit_date, Oracle can't "jump" to a specific section of the index.


-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;
-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Questions:
-- a) What scan type did the second query use?
-- a full scan 
-- b) Why does wrapping a column in a function break index use?
-- When a function like TO_CHAR(), TRUNC(), or UPPER() is applied, the database can no longer compare your search term against the sorted list it has.
-- c) How would you rewrite the second query to allow index use?
SELECT * FROM patient_visits WHERE patient_id = 5432;


-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why?

-- yes, because there is a need to filter data by date range, so we can use a range index. Also, during an ETL, we can expect more read queries, so an index would benefit our performance.

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add?

-- any at all, there are an important amount of inserts to be done, an index would affect the performance, and the order status has few possible values, so having an index there makes no sense.
-- but if reading performance is more important, then we can use an index for customer_id.

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?

-- we can use an unique index for customer_id.