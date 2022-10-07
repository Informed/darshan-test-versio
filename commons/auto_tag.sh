#!/bin/bash

#get highest tag number
APPNAME=$1
VERSION=`git describe  --match "*$APPNAME*" --abbrev=0 --tags`
#replace . with space so can split into an array
APPVERSIONS=(${VERSION//-/ })
VERSION_BITS=(${APPVERSIONS[1]//./ })

#get number parts and increase last one by 1

VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM3=`echo $VNUM3 | sed 's/-.*//'`

# Check for #major or #minor in commit message and increment the relevant version number
MAJOR=`git log --format=%B -n 1 HEAD | grep '#major'`
MINOR=`git log --format=%B -n 1 HEAD | grep '#minor'`

if [ "$MAJOR" ]; then
    echo "INFO: Update major version"
    VNUM1=$((VNUM1+1))
    VNUM2=0
    VNUM3=0
elif [ "$MINOR" ]; then
    echo "INFO: Update minor version"
    VNUM2=$((VNUM2+1))
    VNUM3=0
else
    echo "INFO: Update patch version"
    VNUM3=$((VNUM3+1))
fi

#create new tag
NEW_TAG="$APPNAME-$VNUM1.$VNUM2.$VNUM3"
echo "export GIT_TAG=$NEW_TAG" >> $BASH_ENV

echo "INFO: Updating $VERSION to $NEW_TAG"

#only tag if no tag already (would be better if the git describe command above could have a silent option)
echo "INFO: Tagged with $NEW_TAG (Ignoring fatal:cannot describe - this means commit is untagged) "
git tag $NEW_TAG 
git push --tags 1> /dev/null

## If its prod commit 
## Get the 