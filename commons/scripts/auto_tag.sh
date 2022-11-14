#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Missing Argument -- Application Name."
    echo "Usage: $0 [application name]"
    exit 1
fi

appName=$1

# Get Current Tags for an appName
currentTag=$( git tag --list --sort=committerdate | grep -w "${appName}" | tail -1 )

appVersions=(${currentTag//-/ })
tagToBits=(${appVersions[1]//./ })
suffix=(${appVersions[2]})

# Get number parts and increment by 1
if [ -z ${tagToBits[0]} ]; then
    majorVersion="0"
else
    majorVersion=${tagToBits[0]}
    majorVersion=$( echo $majorVersion | sed 's/-.*//' )
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

if [ -z $suffix ]; then
    preRelease="rc1"
else
    preRelease=$suffix
fi

gitCommitMessage=$( git log --format=%B -n 1 HEAD | sed '/^$/d' | egrep -i '^MAJOR|^MINOR|^PATCH|^FIX' | cut -d':' -f1 |  awk {'print tolower($0)'} )

if [[ $gitCommitMessage == "major" ]]; then
    majorVersion=$(( majorVersion+1 ))
    minorVersion=0
    patchVersion=0
    preRelease="rc1"
elif [[ $gitCommitMessage == "minor" ]]; then
    minorVersion=$(( minorVersion+1 ))
    patchVersion=0
    preRelease="rc1"
elif [[ $gitCommitMessage == "patch" ]]; then
    patchVersion=$(( patchVersion+1 ))
    preRelease="rc1"
elif [[ $gitCommitMessage == "fix" ]]; then
    preReleaseVersion=(${appVersions[2]//rc/})
    preReleaseVersionNumber=$(( preReleaseVersion+1 ))
    echo $preReleaseVersionNumber
    preRelease=rc$preReleaseVersionNumber
else
    patchVersion=$(( patchVersion+1 ))
fi

newTag="${appName}-${majorVersion}.${minorVersion}.${patchVersion}-${preRelease}"

echo "export GIT_TAG=${newTag}" >> $BASH_ENV

if [[ "${CIRCLE_PULL_REQUEST##*/}" = "" ]]; then
    echo "Pull Request Merge to main branch event..."
    echo "Current Tag for ${appName} is: ${currentTag}"
    echo "${appName} will be tagged with ${newTag}"
    git tag $newTag
    git push --tags
fi
