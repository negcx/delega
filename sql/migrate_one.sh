#!/bin/bash

DIR=`dirname $0`

if [ "$1" != "" ]; then
    if [ "$2" != "" ]; then
        echo "Applying migration $2"
        psql -d $1 -q -w -f $DIR/migrations/$2
    else
        echo "Missing required parameter: migration filename"
    fi
else
    echo "Missing required parameter: database name."
fi
