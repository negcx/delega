#!/bin/bash

DIR=`dirname $0`

DB_NAME=${1:-$DATABASE_URL}

if [ "$DB_NAME" != "" ]; then
    while read p; do
        source $DIR/migrate_one.sh $1 $p
    done < $DIR/migrations.txt
else
    echo "Missing required parameter: database name."
fi
