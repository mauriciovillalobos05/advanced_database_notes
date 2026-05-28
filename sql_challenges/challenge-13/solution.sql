-- Step 1

CREATE TABLE agents (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  DEFAULT 'developer' NOT NULL,
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP
);

CREATE TABLE tickets (
    ticket_id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200)  NOT NULL,
    status        VARCHAR2(20)   DEFAULT 'open' NOT NULL,
    priority      VARCHAR2(10)   DEFAULT 'medium' NOT NULL,
    created_at    TIMESTAMP      DEFAULT SYSTIMESTAMP,
    assigned_to   NUMBER         REFERENCES agents(id),
    resolved_at  TIMESTAMP,
    CONSTRAINT chk_ticket_status CHECK (
        status IN ('open', 'in_progress', 'blocked', 'resolved', 'cancelled')
    ),
    CONSTRAINT chk_ticket_priority CHECK (
        priority IN ('low', 'medium', 'high', 'critical')
    )
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id       NUMBER       NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER       NOT NULL REFERENCES agents(id),
    assigned_by   NUMBER       REFERENCES agents(id),
    valid_from    TIMESTAMP    NOT NULL,
    valid_to      TIMESTAMP    -- NULL = current assignment
);

-- Step 2

INSERT INTO agents (name, email, team, role) VALUES ('Alice Chen',   'alice@example.com',   'Platform',   'senior');
INSERT INTO agents (name, email, team, role) VALUES ('Bob Martinez', 'bob@example.com',     'Platform',   'developer');
INSERT INTO agents (name, email, team, role) VALUES ('Carol Smith',  'carol@example.com',   'Frontend',   'senior');
INSERT INTO agents (name, email, team, role) VALUES ('Dave Kim',     'dave@example.com',    'Frontend',   'developer');
INSERT INTO agents (name, email, team, role) VALUES ('Eve Johnson',  'eve@example.com',     'Data',       'senior');
INSERT INTO agents (name, email, team, role) VALUES ('Frank Lee',    'frank@example.com',   'Data',       'developer');
INSERT INTO agents (name, email, team, role) VALUES ('Grace Wang',   'grace@example.com',   'Platform',   'developer');
INSERT INTO agents (name, email, team, role) VALUES ('Henry Brown',  'henry@example.com',   'Frontend',   'developer');

COMMIT;

INSERT INTO TICKETS (title, status, priority, assigned_to, resolved_at) VALUES
('Fix login redirect bug', 'resolved', 'high', 1, TIMESTAMP '2026-02-02 14:00:00');
INSERT INTO tickets (title, status, priority, assigned_to, resolved_at) VALUES
('Fix payment API timeout', 'resolved', 'critical', 2, TIMESTAMP '2026-02-05 10:30:00');

INSERT INTO tickets (title, status, priority, assigned_to, resolved_at) VALUES
('Update dashboard chart rendering', 'resolved', 'medium', 3, TIMESTAMP '2026-02-06 16:45:00');

INSERT INTO tickets (title, status, priority, assigned_to, resolved_at) VALUES
('Resolve mobile navigation overlap', 'resolved', 'high', 4, TIMESTAMP '2026-02-08 09:15:00');

INSERT INTO tickets (title, status, priority, assigned_to, resolved_at) VALUES
('Optimize database query performance', 'resolved', 'critical', 5, TIMESTAMP '2026-02-10 13:20:00');

COMMIT;

-- Step 3

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Initial assignment: log who was assigned at creation time
        INSERT INTO ticket_assignments (ticket_id, assigned_to, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, :NEW.created_at);
    ELSIF UPDATING THEN
        -- Close the previous assignment
        UPDATE ticket_assignments
           SET valid_to = CURRENT_TIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;
        -- Open the new assignment
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, CURRENT_TIMESTAMP);
    END IF;
END;
/

-- Step 4

CREATE TABLE dim_agent (
    agent_key            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name        VARCHAR2(100) NOT NULL,
    team        VARCHAR2(50)  NOT NULL
);

CREATE TABLE fact_ticket_daily (
    fact_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key       VARCHAR2(10) NOT NULL,
    agent_key       NUMBER  NOT NULL  REFERENCES dim_agent(agent_key),
    status        VARCHAR2(20) NOT NULL,
    priority      VARCHAR2(10)   NOT NULL,
    tickets_created NUMBER,
    tickets_resolved NUMBER
);

-- Step 5

INSERT INTO dim_agent (agent_name, team)
VALUES ('Alice Chen', 'Platform');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Bob Martinez', 'Platform');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Carol Smith', 'Frontend');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Dave Kim', 'Frontend');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Eve Johnson', 'Data');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Frank Lee', 'Data');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Grace Wang', 'Platform');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Henry Brown', 'Frontend');

COMMIT;

-- Step 6

tickets_df = pd.read_sql("SELECT * FROM tickets", engine)
assignments_df = pd.read_sql("SELECT * FROM ticket_assignments", engine)

# Ensure datetime types for accurate comparisons
tickets_df['created_at'] = pd.to_datetime(tickets_df['created_at'])
tickets_df['resolved_at'] = pd.to_datetime(tickets_df['resolved_at'])
assignments_df['valid_from'] = pd.to_datetime(assignments_df['valid_from'])
assignments_df['valid_to'] = pd.to_datetime(assignments_df['valid_to'])

merged_df = pd.merge(tickets_df, assignments_df, on='ticket_id', suffixes=('_curr', '_hist'))

created_mask = (merged_df['valid_from'] <= merged_df['created_at']) & \
               (merged_df['valid_to'].isnull() | (merged_df['valid_to'] > merged_df['created_at']))
created_df = merged_df[created_mask].copy()
created_df['date_key'] = created_df['created_at'].dt.strftime('%Y%m%d').astype(int)

created_agg = created_df.groupby(
    ['date_key', 'assigned_to_hist', 'status', 'priority']
).size().reset_index(name='tickets_created')

resolved_mask = merged_df['resolved_at'].notnull() & \
                (merged_df['valid_from'] <= merged_df['resolved_at']) & \
                (merged_df['valid_to'].isnull() | (merged_df['valid_to'] > merged_df['resolved_at']))
resolved_df = merged_df[resolved_mask].copy()
resolved_df['date_key'] = resolved_df['resolved_at'].dt.strftime('%Y%m%d').astype(int)

resolved_agg = resolved_df.groupby(
    ['date_key', 'assigned_to_hist', 'status', 'priority']
).size().reset_index(name='tickets_resolved')

fact_df = pd.merge(
    created_agg, 
    resolved_agg, 
    on=['date_key', 'assigned_to_hist', 'status', 'priority'], 
    how='outer'
).fillna(0)

fact_df.rename(columns={'assigned_to_hist': 'agent_key'}, inplace=True)

fact_df.to_sql('fact_ticket_daily', engine, if_exists='append', index=False)

-- Step 7

SELECT 
    d.agent_name,
    f.date_key,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent d 
  ON f.agent_key = d.agent_key
ORDER BY 
    f.date_key DESC, 
    d.agent_name, 
    f.priority;