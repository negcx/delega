BEGIN;

SELECT _v.register_patch('user', ARRAY['0000_init']);

-- TABLE:   user_
--

CREATE TABLE user_ (
    user_id VARCHAR PRIMARY KEY,
    team_id VARCHAR REFERENCES team(team_id),
    tz_offset INTEGER NOT NULL DEFAULT -25200,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER tg_user_timestamp
BEFORE UPDATE ON user_
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

-- All existing todos need to have their users added to the user_ table.

INSERT INTO user_ (user_id) SELECT DISTINCT x.user_id FROM (
    SELECT created_user_id AS user_id FROM todo
    UNION
    SELECT assigned_user_id AS user_id FROM todo
) x;

-- Now that all the todo users are in the users table, add constraints

ALTER TABLE todo ADD CONSTRAINT created_user_id_fkey FOREIGN KEY(created_user_id) REFERENCES user_(user_id);
ALTER TABLE todo ADD CONSTRAINT completed_user_id_fkey FOREIGN KEY(completed_user_id) REFERENCES user_(user_id);


-- Modify the todo table to use an enum to track multiple 
-- possible todo states, adding the state REJECTED
-- Add a timestamp to track the rejected datetime and user

CREATE TYPE todo_status AS ENUM ('NEW', 'COMPLETE', 'REJECTED');

ALTER TABLE todo ADD COLUMN status todo_status DEFAULT 'NEW';
ALTER TABLE todo ADD COLUMN rejected_at TIMESTAMPTZ;
ALTER TABLE todo ADD COLUMN rejected_user_id VARCHAR REFERENCES user_(user_id);

UPDATE todo SET status = 'NEW' WHERE is_complete = FALSE;
UPDATE todo SET status = 'COMPLETE' WHERE is_complete = TRUE;

DROP INDEX team_created_user_idx;
DROP INDEX team_assigned_user_idx;
ALTER TABLE todo DROP COLUMN is_complete;

CREATE INDEX team_created_user_idx ON todo (team_id, created_user_id, status);
CREATE INDEX team_assigned_user_idx ON todo (team_id, assigned_user_id, status);

CREATE OR REPLACE FUNCTION trigger_completed_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'COMPLETE' AND OLD.status != 'COMPLETE' THEN
        NEW.completed_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_rejected_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'REJECTED' AND OLD.status != 'REJECTED' THEN
        NEW.rejected_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_todo_rejected_timestamp
BEFORE UPDATE ON todo
FOR EACH ROW
EXECUTE PROCEDURE trigger_rejected_timestamp();

COMMIT;