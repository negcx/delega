BEGIN;

SELECT _v.register_patch('feedback', ARRAY['0000_init', 'user']);

CREATE TABLE feedback(
    feedback_id SERIAL PRIMARY KEY,
    user_id VARCHAR NOT NULL REFERENCES user_(user_id),
    feedback VARCHAR NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER tg_feedback
BEFORE UPDATE ON feedback
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

COMMIT;