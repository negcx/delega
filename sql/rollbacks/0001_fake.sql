BEGIN;

SELECT _v.unregister_patch('0001_fake');

ALTER TABLE team DROP COLUMN fake_column;

COMMIT;