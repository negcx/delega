#!/bin/bash

DIR=`dirname $0`

DB_NAME=${1:-$DELEGA_DB}

dropdb $DB_NAME

if [ "$DB_NAME" != "" ]; then
    echo "Creating database $DB_NAME..."
    createdb $DB_NAME

    echo "Installing Versioning..."
    psql -d $DB_NAME --quiet -w -f $DIR/Versioning/install.versioning.sql

    echo "Applying all migrations..."
    source $DIR/migrate.sh $DB_NAME

    psql -d $DB_NAME -q -w -f $DIR/seed.sql
else
    echo "Missing required parameter: database name."
fi
