BEGIN;

SELECT _v.register_patch('user_team', ARRAY['user']);

UPDATE user_
    SET team_id = (SELECT team_id FROM todo WHERE created_user_id = user_id OR assigned_user_id = user_id LIMIT 1)
WHERE team_id IS NULL;

ALTER TABLE user_ ALTER COLUMN team_id SET NOT NULL;

COMMIT;