#!/bin/bash

DIR=`dirname $0`

DB_NAME=${1:-$DELEGA_DB}

dropdb $DB_NAME

if [ "$DB_NAME" != "" ]; then
    echo "Creating database $DB_NAME..."
    createdb $DB_NAME

    source $DIR/setup.sh $1
else
    echo "Missing required parameter: database name."
fi
