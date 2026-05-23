# Advanced SQL Analytics & Operational Reporting Notes

## 1. Conditional Aggregation (The `SUM(CASE)` Technique)
* **The Concept:** Embedding conditional `CASE` logic inside an aggregation function to dynamically bucket data into specific columns during a single table scan.
* **Why it Matters:** Replaces blind `COUNT(*)` or `COUNT(column)` which counts *all* non-NULL values (including `0`). Using `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` ensures mathematically precise filtering.
* **Operational Application:** * Separating historical total task volumes from immediate active workloads (`open`, `in_progress`, `blocked`).
    * Calculating a clean baseline denominator for key performance indicators (KPIs).

## 2. Advanced Resolution Time & Distribution Metrics
* **The Mean vs. Median Trap:** Standard averages (`AVG`) are highly sensitive to extreme outliers (e.g., a single ticket left open for 6 months by accident). A heavily skewed distribution will misrepresent true team velocity.
* **Solution:** Pair the Mean with the **Median (50th Percentile)** to discover the true middle ground of operations.
* **Oracle Syntax:** Uses `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY numeric_column)` to extract stable inverse distribution metrics.
* **Data Integrity Guardrails:** Always include a companion volume column (`COUNT(*)`) and sample-size warning flags to prevent leadership from making strategic decisions based on statistically weak data (e.g., an average calculated from a single completed task).

## 3. High-Fidelity Operational Triage Reports
* **Operational vs. Executive Views:** Executives need high-level aggregate trends, but team leads need actionable worklists. 
* **Composite Risk Scoring:** Real-world severity isn't just a priority string; it's a factor of impact *and* time delayed. 
    * *Example Matrix:* A `CRITICAL` task is a risk at $>0$ days overdue, but a `MEDIUM` task might only escalate to severe status after $>5$ days overdue.
* **Date Normalization:** When calculating date intervals, always wrap elements in `TRUNC()` (e.g., `TRUNC(SYSDATE) - TRUNC(due_date)`) to strip time-of-day data. This eliminates false positives where tasks due by EOD are flagged as late in the morning.
* **Unified Presentation Layer:** Leveraging `UNION ALL` combined with dummy sorting/padding columns (`NULL AS count`, `'DETAIL' AS row_type`) allows detailed itemized tables to sit cleanly alongside aggregated summary blocks in a single query execution.

## 4. Deconstructing Flawed Metrics

### Flaw A: The Nominal Identifier Trap
* **The Issue:** Running calculations like `AVG(task_id)`.
* **The Reality:** Primary key IDs are nominal labels disguised as numbers. Averaging them results in an arbitrary, useless value. Furthermore, due to auto-incrementing integers, this calculation injects severe bias toward newer tasks and teams.
* **Correction:** Pivot to relative conversion ratios, such as the **Team Efficiency Rate** (Total Completed Tasks / Total Non-Cancelled Scope).

### Flaw B: Blind Volume "Productivity" Metrics
* **The Issue:** `COUNT(tasks_assigned)` used as a personal productivity metric.
* **The Reality:** This rewards poor behaviors (creating tasks without finishing them, or cherry-picking 50 easy low-effort tickets over 1 complex system rewrite). It also penalizes those taking planned leave or working on cross-functional team enablement.
* **Correction:** Implement a **Weighted Value Per Active Day** metric:
    1.  Assign numerical weights to task tiers (Critical = 5pts, High = 3pts, etc.).
    2.  Filter strictly for `status = 'completed'`.
    3.  Divide total points by unique calendar active completion days (`COUNT(DISTINCT TRUNC(completed_at))`) to normalize for time off.

### Flaw C: The Mixed Data-Type / Inverted Index Trainwreck
* **The Issue:** Expressions like `priority * 10 + DUE_DATE`.
* **The Reality:** Throws an immediate database type-conversion crash (`VARCHAR * NUMBER`). Mathematically, adding to an absolute date object creates an inverted sorting logic where tasks due far into the future outrank current emergencies.
* **Correction:** Map priorities to clean numeric scalar weights inside a CTE, transform due dates into a relative day interval (`due_date - SYSDATE`), and use a balanced algebraic engine: 
$$\text{Urgency Score} = (\text{Priority Weight} \times 100) - \text{Days Until Due}$$

## 5. Architectural Blueprint: The Dual-Stage CTE Pattern
Throughout our optimization work, we established a highly reliable, readable, and performant SQL architecture:

```sql
WITH stage_1_extract_and_clean AS (
    -- STEP 1: Handle text translations, date interval math, and joins.
    -- Keeps raw mathematical clutter separated from final logic.
    SELECT ...
),
stage_2_conditional_buckets AS (
    -- STEP 2: Run SUM(CASE) conditional logic to establish numeric aggregates.
    SELECT ...
)
-- FINAL SELECT: Run clean arithmetic (averages, percentages, triage scores)
-- Apply outer filters, SLA checks, and final presentation sorting.
SELECT ...
```
