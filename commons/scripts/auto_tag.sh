#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Missing Argument -- Application Name."
    echo "Usage: $0 [application name]"
    exit 1
fi

appName=$1

# Get Current Tags for an appName
currentTag=$( git tag --list --sort=v:refname | grep -w "${appName}" | tail -1 )
appVersions=(${currentTag//-/ })
tagToBits=(${appVersions[1]//./ })

# Get number parts and increment by 1
if [ -z ${tagToBits[0]} ]; then
    majorVersion="0"
else
    majorVersion=${tagToBits[0]}
    majorVersion=$( echo $majorVersion | sed 's/v//' )
fi

if [ -z ${tagToBits[1]} ]; then
    minorVersion="0"
else
    minorVersion=${tagToBits[1]}
fi

if [ -z ${tagToBits[2]} ]; then
    patchVersion="0"
else
    patchVersion=${tagToBits[2]}
fi

gitCommitMessage=$( git log --format=%B -n 1 HEAD | sed '/^$/d' | egrep -i '^MAJOR|^MINOR|^PATCH' | cut -d':' -f1 |  awk {'print tolower($0)'} )

if [[ $gitCommitMessage == "major" ]]; then
    majorVersion=$(( majorVersion+1 ))
    minorVersion=0
    patchVersion=0
elif [[ $gitCommitMessage == "minor" ]]; then
    minorVersion=$(( minorVersion+1 ))
    patchVersion=0
elif [[ $gitCommitMessage == "patch" ]]; then
    patchVersion=$(( patchVersion+1 ))
else
    patchVersion=$(( patchVersion+1 ))
fi

newTag="${appName}-v${majorVersion}.${minorVersion}.${patchVersion}"

if [[ "${CIRCLE_PULL_REQUEST##*/}" = "" ]]; then
    echo "Pull Request Merge to main branch event..."
    echo "Current Tag for ${appName} is: ${currentTag}"
    echo "${appName} will be tagged with ${newTag}"
    git tag $newTag
    git push --tags
fi
