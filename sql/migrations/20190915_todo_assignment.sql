BEGIN;

SELECT _v.register_patch('todo_assignment', ARRAY['0000_init', 'user']);

CREATE TABLE todo_assignment (
    todo_assignment_id SERIAL PRIMARY KEY,
    todo_id INT NOT NULL REFERENCES todo(todo_id),

    assigned_to_user_id VARCHAR NOT NULL REFERENCES user_(user_id),
    assigned_by_user_id VARCHAR NOT NULL REFERENCES user_(user_id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER tg_tdoo_assignment_timestamp
BEFORE UPDATE ON todo_assignment
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

INSERT INTO todo_assignment (todo_id, assigned_to_user_id, assigned_by_user_id)
SELECT t.todo_id, t.assigned_user_id, t.created_user_id FROM todo t;

COMMIT;