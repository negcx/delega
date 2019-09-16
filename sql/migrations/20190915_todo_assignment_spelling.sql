BEGIN;

ALTER TRIGGER tg_tdoo_assignment_timestamp ON todo_assignment RENAME TO tg_todo_assignment_timestamp;

COMMIT;