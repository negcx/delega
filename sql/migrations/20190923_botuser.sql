BEGIN;

SELECT _v.register_patch('botuser', ARRAY['0000_init']);

ALTER TABLE team ADD COLUMN bot_access_token VARCHAR;

COMMIT;