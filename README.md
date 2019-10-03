# Delega

Delega is a Slack-first app for tracking and assigning todos to your team within Slack.

The source code is provided for educational purposes only.

To get started:

- Install dependencies with `mix deps.get`
- Setup your environment variables (see below)
- Setup your database with `./sql/setup.sh`
- Start Phoenix endpoint with `mix phx.server`

_Environment Variables_
`SLACK_SIGNING_SECRET` Get this from your Slack API app
`SLACK_CLIENT_ID` Get this from your Slack API app
`SLACK_CLIENT_SECRET` Get this from your Slack API app
`DATABASE_URL` A Postgres URL to the database (e.g. `postgres://localhost:5432/delega_dev`)

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
