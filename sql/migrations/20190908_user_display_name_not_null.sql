BEGIN;

SELECT _v.register_patch('user_names_display_names_not_null', ARRAY['user_names']);

UPDATE user_ SET display_name = '<@' || user_id || '>' WHERE display_name IS NULL;

ALTER TABLE user_ ALTER COLUMN display_name SET NOT NULL;

COMMIT;