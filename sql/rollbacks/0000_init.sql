BEGIN;

SELECT _v.unregister_patch('0000_init');

DROP TRIGGER IF EXISTS tg_todo_timestamp ON todo;
DROP TRIGGER IF EXISTS tg_todo_completed_timestamp ON todo;
DROP INDEX IF EXISTS team_assigned_user_idx;
DROP INDEX IF EXISTS team_created_user_idx;
DROP TABLE IF EXISTS todo;
DROP FUNCTION IF EXISTS trigger_completed_timestamp();
DROP TRIGGER IF EXISTS tg_team_timestamp ON team;
DROP TABLE IF EXISTS team;
DROP FUNCTION IF EXISTS trigger_update_timestamp();

COMMIT;
