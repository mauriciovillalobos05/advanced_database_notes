-- EXERCISE 1: Define "Team Velocity"

/*
1. BUSINESS QUESTION
------------------------------------------------------------
Management wants to understand how productive each team is
in completing work, and compare teams fairly despite
differences in team size or headcount.
*/


/*
2. KPI DEFINITION
------------------------------------------------------------
Team Velocity =
Average number of completed tasks per team member
during a specific one-week period.

Rules:
- Only tasks completed within the selected week count.
- completed_at must fall between the provided date range.
- status must indicate true completion
  (e.g. 'Done', 'Completed').

Data Relationships:
- TASKS is INNER JOINED with USERS
  using the assignment relationship
  to associate each task with a team.
*/


/*
3. EDGE CASES
------------------------------------------------------------
- Unassigned tasks:
  Excluded because they cannot be mapped to a team.

- Cancelled or deferred tasks:
  Excluded by filtering only completed statuses.

- Inactive or quiet team members:
  If a user completes 0 tasks, they may disappear
  from the result set when starting from TASKS.

  This can artificially inflate team velocity.

  To avoid this issue:
  Start from USERS and LEFT JOIN TASKS
  so all team members are included,
  even if they completed zero tasks.
*/


/*
4. UNIT OF MEASUREMENT
------------------------------------------------------------
Count:
Average number of completed tasks
per person, per week.
*/


/*
5. LIMITATIONS / WHY THIS METRIC CAN MISLEAD
------------------------------------------------------------
- Complexity Blindness:
  Completing one highly complex project task
  may require more effort than closing many small tasks.

- Gaming the System:
  Teams may split simple work into many tiny tickets
  to artificially increase velocity numbers.
*/

-- ============================================================================
-- KPI CONTRACT: Team Velocity (Normalized)
-- ============================================================================
-- DEFINITION: The average number of successfully completed tasks per team 
--             member within a specific weekly timeframe.
--
-- WHY NORMALIZED?: The Product team is smaller than Engineering. Raw task counts 
--                  would inherently penalize smaller teams. Normalizing per capita 
--                  ensures fair performance comparison.
--
-- PROS OF NORMALIZATION: Allows cross-team baseline comparisons; accounts for team sizing.
-- CONS OF NORMALIZATION: Treats all tasks as equal effort; ignores task complexity.
-- ============================================================================

WITH individual_counts AS (
    -- Step 1: Calculate total completed tasks for EVERY user in the system.
    -- Using a LEFT JOIN ensures users with 0 completions are counted fairly.
    SELECT 
        u.id AS user_id,
        u.team_id,
        COUNT(t.id) AS total_tasks
    FROM users u
    LEFT JOIN tasks t ON u.id = t.assigned_to 
        AND t.completed_at BETWEEN :initial_date AND :final_date
        -- AND t.status = 'COMPLETED' -- Optional: depending on status architecture
    GROUP BY u.id, u.team_id
),

team_velocities AS (
    -- Step 2: Aggregate individual scores to find the average per team
    SELECT 
        team_id,
        AVG(total_tasks) AS team_velocity
    FROM individual_counts
    WHERE team_id IS NOT NULL
    GROUP BY team_id
)

-- Step 3: Output team velocity alongside a flag for underperforming teams
SELECT 
    team_id,
    ROUND(team_velocity, 2) AS tasks_per_member_sprint,
    CASE 
        WHEN team_velocity < AVG(team_velocity) OVER() THEN 'Below Average'
        ELSE 'On Track / Above Average'
    END AS velocity_flag
FROM team_velocities;

---

-- EXERCISE 2: Define "On-Time Delivery Rate"

/*
============================================================================
KPI CONTRACT: On-Time Delivery Rate (OTDR)
============================================================================

1. BUSINESS QUESTION
----------------------------------------------------------------------------
The product manager wants to understand:

- Are teams delivering work by the agreed deadlines?
- Which priority levels are slipping the most?
- When tasks are late, how late are they on average?


2. KPI DEFINITION
----------------------------------------------------------------------------
On-Time Delivery Rate (OTDR) =
Percentage of tasks completed on or before their due date.

On-Time Rule:
    TRUNC(completed_at) <= due_date

Reason:
- TRUNC removes the time portion from completed_at.
- This ensures a task completed at any time during the due date
  is still considered on time.

Exclusions:
- Tasks without a due_date are excluded entirely.
- These tasks are removed from both:
    * numerator
    * denominator


3. EDGE CASES
----------------------------------------------------------------------------
- End-of-Day Submissions:
  A task completed at 11:59 PM on the due date could incorrectly
  appear late when comparing full timestamps directly.

  Using TRUNC(completed_at) avoids this issue.

- Tasks Without Due Dates:
  Excluded to prevent distortion of the success rate.

- Cancelled Tasks:
  Cancelled work should not count as either:
    * late
    * on time

  These should be excluded using status filters.


4. UNIT OF MEASUREMENT
----------------------------------------------------------------------------
- On-Time Delivery Rate:
    Percentage (%)

- Average Lateness:
    Hours (hrs)


5. LIMITATIONS / WHY THIS METRIC CAN MISLEAD
----------------------------------------------------------------------------
- Scope Creep / Due Date Manipulation:
  Teams may move due dates forward when projects slip.

  This can artificially inflate OTDR and hide delays.

- Priority Misuse:
  Strong performance on low-priority tasks may hide severe delays
  in critical work.

  Breaking the metric down by priority helps mitigate this issue.

============================================================================
*/

SELECT 
    priority,
    ROUND(
        AVG(
            CASE 
                WHEN TRUNC(completed_at) <= due_date THEN 1 
                ELSE 0 
            END
        ) * 100, 2
    ) || '%' AS on_time_delivery_rate,
    
    ROUND(
        AVG(
            CASE 
                WHEN TRUNC(completed_at) > due_date 
                THEN (CAST(completed_at AS DATE) - due_date) * 24 
            END
        ), 1
    ) AS avg_lateness_hours
FROM tasks
WHERE due_date IS NOT NULL 
  AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY 
    CASE priority 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH'     THEN 2 
        WHEN 'MEDIUM'   THEN 3 
        WHEN 'LOW'      THEN 4 
    END;
---

fig.update_traces(
    textposition='inside',
    textinfo='label+percent',
    hovertemplate='<b>%{label}</b><br>Tasks: %{value}<br>Percentage: %{customdata}%<extra></extra>',
    customdata=df_status['pct_of_total']
)

--

-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)

/*
============================================================================
METRIC DESIGN RATIONALE
============================================================================

The Problem with Raw Counts
----------------------------------------------------------------------------
Using a blind COUNT(*) alone can create misleading conclusions.

A high historical task count may create the illusion of strong productivity,
while hiding:
- current operational bottlenecks,
- overloaded teams,
- or completely underutilized teams.


The Conditional Aggregation Solution
----------------------------------------------------------------------------
By separating task statuses into categories such as:
- active_tasks
- completed_tasks

management gains two perspectives simultaneously:

1. Real-Time Operational View
   - Current workload and active capacity.

2. Historical Quality View
   - Completion effectiveness over time
     (measured through completion_rate).


The Denominator Filter
----------------------------------------------------------------------------
Cancelled tasks are intentionally excluded from the completion-rate denominator.

Reason:
Teams should not be penalized for strategic or organizational changes,
such as:
- projects cancelled mid-sprint,
- shifting business priorities,
- product-management decisions.

Including cancelled tasks would artificially reduce completion metrics
and distort team performance evaluations.

============================================================================
*/

WITH team_raw_counts AS (
    SELECT t.name AS team_name,
           COUNT(ts.id) AS total_tasks, 
           SUM(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked', 'completed') THEN 1 ELSE 0 END) AS total_tasks_excluding_blocked,
           SUM(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 ELSE 0 END) AS active_tasks,
           SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks
    FROM   teams t
    LEFT   JOIN users u ON u.team_id = t.id
    LEFT   JOIN tasks ts ON ts.assigned_to = u.id
    GROUP  BY t.id, t.name
)
SELECT 
    team_name,
    total_tasks,
    active_tasks,
    ROUND(
        CASE
            WHEN total_tasks_excluding_blocked > 0 
                THEN completed_tasks / total_tasks_excluding_blocked
            ELSE 0
        END,
        2
    ) AS completion_rate,
    CASE 
        WHEN active_tasks > 10 THEN 'Overloaded'
        WHEN active_tasks > 4 AND active_tasks < 11 THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM team_raw_counts
ORDER BY active_tasks DESC;

---

-- EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)

/*
============================================================================
KPI CONTRACT: Resolution Time & SLA Compliance
============================================================================

1. BUSINESS QUESTION
----------------------------------------------------------------------------
The product manager wants to understand:

- How quickly are tasks being resolved based on urgency?
- Which priority levels contain major bottlenecks or extreme delays?
- Are teams meeting their promised Service Level Agreements (SLAs)?


2. KPI DEFINITION
----------------------------------------------------------------------------
Resolution Time =
The elapsed duration between:
    created_at
and
    completed_at

Granularity:
- Metrics are segmented by priority level
  to isolate operational workflows independently.

Aggregations Used:
- Average (Mean):
    Measures overall performance trends.

- Median (50th Percentile):
    Measures the typical resolution time while reducing
    distortion caused by extreme outliers.


3. EDGE CASES
----------------------------------------------------------------------------
- Single-Task Priorities:
  If a priority category contains only one completed task,
  the average becomes statistically unreliable and highly volatile.

  Mitigation:
  - Output COUNT(*) as volume context.
  - Add a warning flag for low sample sizes.

- Extreme Outliers:
  A single abandoned or blocked ticket left unresolved
  for months can dramatically inflate averages.

  Mitigation:
  The query also reports:
  - MIN resolution time
  - MAX resolution time
  - MEDIAN resolution time

  to provide distribution visibility beyond the average.


4. UNIT OF MEASUREMENT
----------------------------------------------------------------------------
- Resolution Times / SLA Targets:
    Decimal Hours (hrs)

- Task Volume:
    Count of completed tasks


5. LIMITATIONS / WHY THIS METRIC CAN MISLEAD
----------------------------------------------------------------------------
- Aggregating All Priorities Together:
  Combining:
  - critical incidents,
  - high-priority bugs,
  - and low-priority documentation tasks

  into one overall average can hide operational failures.

  Example:
  Critical bugs may be severely delayed even when
  low-priority tasks are resolved quickly.

- Missing or Incorrect Timestamps:
  If tasks are manually closed without accurate timestamp updates,
  or timestamps are backdated,
  the duration calculations become unreliable.

============================================================================
*/

WITH raw_resolution_times AS (
    SELECT 
        priority,

        -- Convert Oracle INTERVAL into decimal hours
        (
            (EXTRACT(DAY FROM (completed_at - created_at)) * 24) +
            EXTRACT(HOUR FROM (completed_at - created_at)) +
            (EXTRACT(MINUTE FROM (completed_at - created_at)) / 60)
        ) AS resolution_hours

    FROM tasks
    WHERE status = 'completed'
      AND completed_at IS NOT NULL
      AND priority IS NOT NULL
)

SELECT 
    priority,

    -- Important context: averages with tiny sample sizes are unreliable
    COUNT(*) AS completed_task_count,

    -- Mean resolution time
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,

    -- Median resolution time
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY resolution_hours),
        2
    ) AS median_resolution_hours,

    -- Fastest completion
    ROUND(MIN(resolution_hours), 2) AS fastest_resolution_hours,

    -- Slowest completion
    ROUND(MAX(resolution_hours), 2) AS slowest_resolution_hours,

    -- SLA target by priority
    CASE
        WHEN priority = 'critical' THEN 24
        WHEN priority = 'high' THEN 72
        WHEN priority = 'medium' THEN 168
        WHEN priority = 'low' THEN 336
        ELSE NULL
    END AS sla_target_hours,

    -- SLA compliance check
    CASE
        WHEN AVG(resolution_hours) <= 
            CASE
                WHEN priority = 'critical' THEN 24
                WHEN priority = 'high' THEN 72
                WHEN priority = 'medium' THEN 168
                WHEN priority = 'low' THEN 336
            END
        THEN 'Target Met'
        ELSE 'Target Missed'
    END AS target_met,

    -- Warn about statistically weak sample sizes
    CASE
        WHEN COUNT(*) = 1 THEN 'Single Task Sample'
        WHEN COUNT(*) < 5 THEN 'Low Sample Size'
        ELSE 'Reliable Sample'
    END AS sample_size_warning

FROM raw_resolution_times
GROUP BY priority
ORDER BY avg_resolution_hours DESC;

---

-- EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)

-- ============================================================
-- BUSINESS QUESTION
-- ============================================================
-- The operations and management teams want to know:
-- "Which open commitments have missed their deadlines,
-- who is responsible for them, and how should we
-- prioritize our outreach to mitigate severe project delays?"
--
-- ============================================================
-- EXACT METRIC DEFINITION
-- ============================================================
-- An "Overdue Task" is any ticket where:
--   due_date < TRUNC(SYSDATE)
-- AND
--   status indicates the task is still active or ignored
--   (excluding completed and cancelled tasks).
--
-- Days Overdue:
--   Calculated as:
--     TRUNC(SYSDATE) - TRUNC(due_date)
--
-- SLA Severity Triage:
--   A composite severity model combining:
--     - Task priority
--     - Magnitude of delay
--
-- Example severity rules:
--   - Critical  -> Immediate escalation
--   - High      -> Escalate if overdue > 2 days
--   - Medium    -> Escalate if overdue > 5 days
--
-- ============================================================
-- EDGE CASES
-- ============================================================
-- 1. Time-of-Day False Positives
-- ------------------------------------------------------------
-- Comparing timestamps directly against due dates may flag
-- tasks as overdue too early (e.g., 9:00 AM on the due date).
--
-- Using TRUNC() on both SYSDATE and due_date ensures
-- tasks are only considered overdue after the entire
-- calendar day has passed.
--
-- 2. Missing Assignments
-- ------------------------------------------------------------
-- Some overdue tasks may not have assigned teams or owners.
--
-- LEFT JOIN chains are required to preserve these records
-- so they remain visible to management instead of being
-- accidentally excluded from the report.
--
-- ============================================================
-- UNIT OF MEASUREMENT
-- ============================================================
-- Granular rows:
--   Individual task-level records including:
--     - task metadata
--     - ownership information
--     - integer days_overdue
--
-- Summary aggregates:
--   - Total overdue volume using COUNT()
--   - Average overdue duration using AVG(days_overdue)
--
-- ============================================================
-- LIMITATIONS / MISLEADING SCENARIOS
-- ============================================================
-- 1. Ghost Tasks / Zombie Backlogs
-- ------------------------------------------------------------
-- Abandoned tasks that remain open for months can heavily
-- inflate average overdue duration metrics and distort
-- operational priorities away from current blockers.
--
-- 2. Arbitrary Deadlines
-- ------------------------------------------------------------
-- If deadlines are assigned aggressively without engineering
-- alignment, the report may appear perpetually unhealthy
-- even when delivery velocity is sustainable.
--
-- This can reduce the reliability of overdue metrics as a
-- true operational performance indicator.
-- ============================================================

WITH overdue_base AS (
    SELECT 
        ts.title AS task_title,
        u.full_name AS assignee_name,
        t.name AS team_name,
        UPPER(ts.priority) AS priority,
        ts.due_date,

        -- Number of full days overdue
        (TRUNC(SYSDATE) - TRUNC(ts.due_date)) AS days_overdue

    FROM tasks ts

    LEFT JOIN users u 
        ON ts.assigned_to = u.id

    LEFT JOIN teams t 
        ON u.team_id = t.id

    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
),

overdue_with_severity AS (
    SELECT 
        task_title,
        assignee_name,
        team_name,
        priority,
        due_date,
        days_overdue,

        CASE 
            WHEN priority = 'CRITICAL' AND days_overdue > 0
                THEN 'CRITICAL'

            WHEN priority = 'HIGH' AND days_overdue > 2
                THEN 'HIGH'

            WHEN priority = 'MEDIUM' AND days_overdue > 5
                THEN 'MEDIUM'

            ELSE 'LOW'
        END AS severity

    FROM overdue_base
)

SELECT *
FROM (

    -- DETAIL REPORT
    SELECT
        'DETAIL' AS row_type,

        task_title,
        assignee_name,
        team_name,
        priority,
        due_date,
        days_overdue,
        severity,

        NULL AS overdue_task_count,
        NULL AS avg_days_overdue

    FROM overdue_with_severity

    UNION ALL

    -- SUMMARY REPORT
    SELECT
        'SUMMARY' AS row_type,

        NULL AS task_title,
        NULL AS assignee_name,
        NULL AS team_name,
        NULL AS priority,
        NULL AS due_date,
        NULL AS days_overdue,

        severity,

        COUNT(*) AS overdue_task_count,

        ROUND(AVG(days_overdue), 2) AS avg_days_overdue

    FROM overdue_with_severity
    GROUP BY severity

)

ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    days_overdue DESC NULLS LAST;

---

-- EXERCISE 6: Fix the "Productivity Score"

-- ============================================================
-- BUSINESS QUESTION
-- ============================================================
-- Management wants to know:
-- "Who are our top value contributors, and how much
-- meaningful, high-priority work is each team member
-- consistently delivering on the days they are active?"
--
-- ============================================================
-- EXACT METRIC DEFINITION
-- ============================================================
-- Weighted Productivity Score:
--   The total weighted points earned from completed tasks,
--   divided by the number of unique calendar days where
--   the employee completed at least one task.
--
-- Formula:
--   SUM(weighted_points)
--   /
--   COUNT(DISTINCT TRUNC(completed_at))
--
-- Point Architecture:
--   - CRITICAL = 5 points
--   - HIGH     = 3 points
--   - MEDIUM   = 2 points
--   - LOW      = 1 point
--
-- Required Filters:
--   - status = 'completed'
--   - completed_at IS NOT NULL
--
-- Join Strategy:
--   A LEFT JOIN from USERS to TASKS is required so users
--   with zero completed tasks still appear in the report.
--
-- ============================================================
-- EDGE CASES
-- ============================================================
-- 1. Vacation / Leave Normalization
-- ------------------------------------------------------------
-- Using an absolute completion total would unfairly penalize
-- employees who took vacation, sick leave, or temporary leave.
--
-- Dividing by active completion days normalizes productivity
-- relative to the days the employee was actually active.
--
-- 2. Zero Output Users
-- ------------------------------------------------------------
-- New hires, blocked employees, or inactive users may have
-- zero completed tasks.
--
-- Using LEFT JOIN preserves these users in the report with
-- a productivity score of 0 instead of excluding them.
--
-- ============================================================
-- UNIT OF MEASUREMENT
-- ============================================================
-- Productivity is measured in:
--   Points Per Active Day (pts/day)
--
-- ============================================================
-- LIMITATIONS / MISLEADING SCENARIOS
-- ============================================================
-- 1. Weight Arbitrage
-- ------------------------------------------------------------
-- Employees may attempt to artificially classify routine
-- tasks as higher priority (e.g., CRITICAL) to maximize
-- their personal productivity score.
--
-- This can distort the reliability of the metric unless
-- task priority assignment is governed consistently.
--
-- 2. Ineffective Collaboration Measurement
-- ------------------------------------------------------------
-- This metric only evaluates individually assigned tasks.
--
-- High-impact collaborative work such as:
--   - mentoring
--   - pair programming
--   - code reviews
--   - removing blockers
--   - architecture support
--
-- may produce low individual scores despite generating
-- significant team-wide productivity gains.
-- ============================================================

WITH user_task_metrics AS (
    SELECT 
        u.id AS user_id,
        u.full_name,
        -- Count unique calendar days where work was submitted
        COUNT(DISTINCT TRUNC(ts.completed_at)) AS active_days,
        -- Apply weight rules inside the SUM aggregation
        SUM(
            CASE UPPER(ts.priority)
                WHEN 'CRITICAL' THEN 5
                WHEN 'HIGH'     THEN 3
                WHEN 'MEDIUM'   THEN 2
                WHEN 'LOW'      THEN 1
                ELSE 0
            END
        ) AS total_weighted_points,
        COUNT(ts.id) AS total_completed_tasks
    FROM users u
    LEFT JOIN tasks ts ON ts.assigned_to = u.id 
        AND ts.status = 'completed' 
        AND ts.completed_at IS NOT NULL
    GROUP BY u.id, u.full_name
)

SELECT 
    full_name,
    total_completed_tasks,
    total_weighted_points,
    active_days,
    ROUND(
        CASE 
            WHEN active_days > 0 THEN total_weighted_points / active_days
            ELSE 0 
        END, 2
    ) AS value_per_active_day
FROM user_task_metrics
ORDER BY value_per_active_day DESC, total_weighted_points DESC;

---

-- EXERCISE 7: Fix the "Team Efficiency"

-- ============================================================
-- BUSINESS QUESTION
-- ============================================================
-- Management wants to know:
-- "Which teams are most effective at closing out the
-- commitments assigned to them, and which teams are
-- struggling to get their assigned work across the finish line?"
--
-- ============================================================
-- EXACT METRIC DEFINITION
-- ============================================================
-- Team Efficiency:
--   The percentage of completed tasks relative to all
--   non-cancelled tasks assigned to a team.
--
-- Formula:
--   completed_tasks
--   /
--   total_non_cancelled_tasks
--   * 100
--
-- Required Filters:
--   - Exclude status = 'cancelled' from the denominator
--
-- Business Rationale:
--   Cancelled tasks represent changing business priorities
--   or scope changes, not operational inefficiency.
--
-- Join Strategy:
--   Use a continuous LEFT JOIN chain:
--     TEAMS -> USERS -> TASKS
--
-- This ensures teams with zero assignments are preserved
-- in the final report instead of disappearing entirely.
--
-- ============================================================
-- EDGE CASES
-- ============================================================
-- 1. Zero-Workload Teams
-- ------------------------------------------------------------
-- Newly created or specialized teams may have zero assigned
-- tasks, which would cause:
--
--   ORA-01476: divisor is equal to zero
--
-- A defensive CASE expression must be used to safely handle
-- division when the denominator equals zero.
--
-- Example:
--   CASE
--       WHEN total_tasks = 0 THEN 0
--       ELSE completed_tasks / total_tasks
--   END
--
-- 2. Unassigned Team Activity
-- ------------------------------------------------------------
-- Some tasks may exist with incomplete historical updates
-- or partial assignment records.
--
-- Using LEFT JOIN ensures these tasks remain visible in the
-- workload pool so efficiency calculations remain transparent.
--
-- ============================================================
-- UNIT OF MEASUREMENT
-- ============================================================
-- Efficiency is measured as:
--   Percentage (%)
--
-- ============================================================
-- LIMITATIONS / MISLEADING SCENARIOS
-- ============================================================
-- 1. Backlog Dump Effect
-- ------------------------------------------------------------
-- If management suddenly assigns a large volume of
-- low-priority or long-term tasks to a team, the team's
-- efficiency percentage may sharply decline immediately,
-- even if daily productivity remains strong.
--
-- This can temporarily distort operational performance.
--
-- 2. Cherry-Picking Behavior
-- ------------------------------------------------------------
-- Teams may artificially improve efficiency metrics by:
--   - prioritizing small, quick tasks
--   - delaying complex structural work
--   - avoiding high-effort initiatives
--
-- This can create high completion percentages while major
-- business bottlenecks remain unresolved.
-- ============================================================

WITH team_efficiency_base AS (
    SELECT 
        t.id AS team_id,
        t.name AS team_name,
        -- The true commitment denominator (excludes cancelled scope)
        SUM(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked', 'completed') THEN 1 ELSE 0 END) AS total_valid_tasks,
        -- The target numerator
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
)

SELECT 
    team_name,
    completed_tasks,
    total_valid_tasks AS net_assigned_scope,
    ROUND(
        CASE 
            WHEN total_valid_tasks > 0 THEN (completed_tasks / total_valid_tasks) * 100
            ELSE 0 
        END, 2
    ) || '%' AS team_efficiency_rate
FROM team_efficiency_base
ORDER BY ROUND(CASE WHEN total_valid_tasks > 0 THEN (completed_tasks / total_valid_tasks) * 100 ELSE 0 END, 2) DESC;

---

-- EXERCISE 8: Fix the "Urgency Index"

-- ============================================================
-- PROBLEM DESCRIPTION
-- ============================================================
-- The original query attempted to perform mathematical
-- calculations directly on:
--
--   - VARCHAR2 text values
--   - Absolute DATE objects
--
-- This caused:
--   - syntax and datatype failures
--   - invalid arithmetic operations
--   - inverted prioritization logic
--
-- As a result, tasks with future deadlines could incorrectly
-- outrank urgent or overdue tasks.
--
-- ============================================================
-- SOLUTION APPROACH
-- ============================================================
-- The corrected implementation applies a normalization
-- strategy before performing scoring calculations.
--
-- Step 1:
--   Convert textual priority labels into a standardized
--   numeric scoring scale using a Common Table Expression (CTE).
--
-- Example:
--   CRITICAL -> 5
--   HIGH     -> 3
--   MEDIUM   -> 2
--   LOW      -> 1
--
-- Step 2:
--   Transform absolute calendar DATE values into a relative
--   scalar integer metric:
--
--     days_until_due
--
-- This enables valid mathematical comparisons and ranking.
--
-- Step 3:
--   Combine the normalized priority score and relative
--   deadline distance using a weighted algebraic formula
--   to generate a stable and logically correct ranking model.
--
-- ============================================================
-- BENEFITS OF THE REFACTOR
-- ============================================================
-- - Eliminates datatype arithmetic errors
-- - Produces deterministic ranking behavior
-- - Prevents future-due tasks from outranking emergencies
-- - Separates business logic into maintainable stages
-- - Improves readability and debugging capability
-- ============================================================

WITH task_urgency_components AS (
    SELECT 
        id AS task_id,
        title AS task_title,
        UPPER(priority) AS priority,
        due_date,
        CASE UPPER(priority)
            WHEN 'CRITICAL' THEN 4
            WHEN 'HIGH'     THEN 3
            WHEN 'MEDIUM'   THEN 2
            WHEN 'LOW'      THEN 1
            ELSE 0
        END AS priority_weight,
        -- Positive if due in future, 0 if due today, negative if overdue
        (TRUNC(due_date) - TRUNC(SYSDATE)) AS days_until_due
    FROM tasks
    WHERE status NOT IN ('completed', 'cancelled')
      AND due_date IS NOT NULL
)

SELECT 
    task_title,
    priority,
    due_date,
    days_until_due,
    -- Composite mathematical engine
    ((priority_weight * 100) - days_until_due) AS urgency_index,
    -- User-friendly operational label
    CASE 
        WHEN days_until_due < 0 THEN 'OVERDUE'
        WHEN days_until_due = 0 THEN 'DUE TODAY'
        WHEN days_until_due <= 3 THEN 'IMMINENT RISK'
        ELSE 'BUFFERED'
    END AS operational_status
FROM task_urgency_components
ORDER BY urgency_index DESC, due_date ASC;