BEGIN;

SELECT _v.register_patch('userchannel', ARRAY['user']);

ALTER TABLE user_ ADD COLUMN channel_id VARCHAR;

COMMIT;