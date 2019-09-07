BEGIN;

SELECT _v.register_patch('user_names', ARRAY['user']);

ALTER TABLE user_ ADD COLUMN display_name VARCHAR;
ALTER TABLE user_ ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

UPDATE user_ SET is_deleted = FALSE;

ALTER TABLE user_ ALTER COLUMN is_deleted SET NOT NULL;

COMMIT;