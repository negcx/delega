BEGIN;

SELECT _v.register_patch('0000_init');

CREATE OR REPLACE FUNCTION trigger_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TABLE team (
    team_id VARCHAR PRIMARY KEY,
    access_token VARCHAR,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER tg_team_timestamp
BEFORE UPDATE ON team
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

CREATE OR REPLACE FUNCTION trigger_completed_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_complete = TRUE AND OLD.is_complete != TRUE THEN
        NEW.completed_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE todo (
    todo_id SERIAL PRIMARY KEY,
    team_id VARCHAR NOT NULL REFERENCES team(team_id),
    created_user_id VARCHAR NOT NULL,
    assigned_user_id VARCHAR NOT NULL,
    completed_user_id VARCHAR,

    todo VARCHAR NOT NULL,

    is_complete BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX team_created_user_idx ON todo (team_id, created_user_id, is_complete);

CREATE INDEX team_assigned_user_idx ON todo (team_id, created_user_id, is_complete);

CREATE TRIGGER tg_todo_completed_timestamp
BEFORE UPDATE ON todo
FOR EACH ROW
EXECUTE PROCEDURE trigger_completed_timestamp();

CREATE TRIGGER tg_todo_timestamp
BEFORE UPDATE ON todo
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

COMMIT;
