BEGIN;

SELECT _v.register_patch('0001_fake');

ALTER TABLE team ADD COLUMN fake_column INT;

COMMIT;