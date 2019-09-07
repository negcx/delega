BEGIN;

SELECT _v.register_patch('channel', ARRAY['0000_init']);

CREATE TABLE todo_channel (
    todo_id INTEGER NOT NULL REFERENCES todo(todo_id),
    channel_id VARCHAR NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY(todo_id, channel_id)
);

CREATE TRIGGER tg_todo_channel_timestamp
BEFORE UPDATE ON todo_channel
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_timestamp();

COMMIT;