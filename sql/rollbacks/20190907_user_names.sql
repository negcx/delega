BEGIN;

SELECT _v.unregister_patch('user_names');

ALTER TABLE user_ DROP COLUMN display_name;
ALTER TABLE user_ DROP COLUMN is_deleted;

COMMIT;