#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Missing Argument -- Version , Target env"
    echo "Usage: $0 [version] [target env]"
    exit 1
fi

version=$1
target_env=$2

if [[ $target_env == "sand/dshah" ]]; then
    newTag=$( echo $version  | awk -F "-" '{print $1,"-",$2 }' | tr -d '[:space:]' )
else    
    newTag=$version
fi

echo "export GIT_TAG=${newTag}" >> $BASH_ENV