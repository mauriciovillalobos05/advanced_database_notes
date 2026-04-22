CREATE OR REPLACE PROCEDURE transfer_funds(
    p_from_account  IN  NUMBER,
    p_to_account    IN  NUMBER,
    p_amount        IN  NUMBER
) AS
    v_from_balance  NUMBER;
BEGIN
    -- Check sufficient funds before doing anything
    SELECT balance INTO v_from_balance
    FROM accounts
    WHERE account_id = p_from_account;

    IF v_from_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient funds in account ' || p_from_account);
    END IF;

    -- Perform the transfer
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

    -- Commit only if both succeed
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Transfer complete: $' || p_amount ||
                         ' from account ' || p_from_account ||
                         ' to account ' || p_to_account);
EXCEPTION
    WHEN OTHERS THEN
        -- Something went wrong — undo everything
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transfer failed. All changes rolled back.');
        RAISE;  -- re-raise the error so the caller knows it failed
END;
/

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:
-- Before: verify balances
SELECT account_id, owner_name, balance FROM accounts WHERE account_id IN (1, 3);

BEGIN
    transfer_funds(3, 1, 50);
END;
/

COMMIT;
 

-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:
EXEC transfer_funds(2, 3, 10000);
SELECT account_id, owner_name, balance FROM accounts WHERE account_id IN (2, 3); --rollbacked successfully
 

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:
CREATE OR REPLACE PROCEDURE transfer_funds(
    p_from_account  IN NUMBER,
    p_to_account    IN NUMBER,
    p_amount        IN NUMBER
) AS
    v_from_balance  NUMBER;
    v_to_balance    NUMBER;
BEGIN
    -- Validate inputs
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Amount must be positive');
    END IF;
    IF p_from_account = p_to_account THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot transfer to the same account');
    END IF;

    -- Lock in consistent order (avoid deadlocks)
    IF p_from_account < p_to_account THEN
        SELECT balance INTO v_from_balance FROM accounts WHERE account_id = p_from_account FOR UPDATE;
        SELECT balance INTO v_to_balance   FROM accounts WHERE account_id = p_to_account   FOR UPDATE;
    ELSE
        SELECT balance INTO v_to_balance   FROM accounts WHERE account_id = p_to_account   FOR UPDATE;
        SELECT balance INTO v_from_balance FROM accounts WHERE account_id = p_from_account FOR UPDATE;
    END IF;

    SAVEPOINT before_transfer;  

    -- Atomic debit
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account
    AND balance >= p_amount;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient funds');
    END IF;

    -- Credit
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    DBMS_OUTPUT.PUT_LINE('Transfer complete: $' || p_amount ||
        ' from account ' || p_from_account ||
        ' to account ' || p_to_account);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO SAVEPOINT before_transfer;
        RAISE_APPLICATION_ERROR(-20003, 'Account not found');
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT before_transfer;  
        RAISE;                                 
END;
 

-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id  IN NUMBER,
    p_amount      IN NUMBER
) AS
BEGIN
    -- 1. Validate amount
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Amount must be positive');
    END IF;

    -- 2. Add p_amount to the account balance
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    -- Catch invalid account (no rows updated)
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account not found');
    END IF;

    -- 3. Commit on success
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deposit complete: $' || p_amount ||
        ' in account ' || p_account_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
 
EXEC deposit_funds(3, 75);

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?

-- reserve the slot + create the appointment record (they must succeed or fail together)

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?

-- The developer's larger transaction gets committed prematurely, before they intended, potentially saving incomplete or inconsistent data. 

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?
-- yes for the calculate_copay(), because we can add functions in our select query if it returns a number, but no for post_payment(), because we cant add procedures.