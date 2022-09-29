#!/bin/bash

# Get the basic outputs for the tagging mechanism
BASE_DIR="$(git rev-parse --show-toplevel )"
if [ $? -ne 0 ]; then
  echo "Not inside a git repo."
  exit 1
fi
export BASE_DIR

# Starting tags with a constant like 'v' i.e v1.0 or v1.0.0 will drastically simplify
# versioning. Since git tag matching occurs with globbing rather than regex's
# In regex world the basic 0.0.0 or 0.0 pattern would be: '^([0-9]*.){0,2}[0-9]*$'
# However without enabling extended globbing, this is impractical. See: `shopt -s extglob`
# First parent option allows us to bypass incremental versions on merge commits.
DESCRIBE="$(git describe --long --first-parent --match "api_handler*" --tags )"

if [ $? -ne 0 ]; then
  echo "Unable to locate tag. Defaulting."
  DESCRIBE="0.0.0-0-$(git rev-parse --short HEAD)"
fi

# Parse the describe output
TAG="$(echo "$DESCRIBE" | awk -F '-' '{print $1}')"
COMMITS="$(echo "$DESCRIBE" | awk -F '-' '{print $2}')"
SHA="$(echo "$DESCRIBE" | awk -F '-' '{print $3}')"
export SHA

# Assumes tag has format: v1.0 or v1.1.0
# Note that MAJOR will always be v1 or v2 etc
MAJOR="$(echo "$TAG" | awk -F '.' '{print $1}')"
MINOR="$(echo "$TAG" | awk -F '.' '{print $2}')"
PREBUILD="$(echo "$TAG" | awk -F '.' '{print $3}')"

# For release candidate releases 
if [ "$PREBUILD" == "rc*" ]; then
  # Ignore the number of commits between since each time you will make a tag
  # to increase the counter by 1
  BUILD="rc$(( "$(echo "$PREBUILD" | tr -d "rc")" + 1 ))"
else
  # This exposes the build as the sum of:
  # the pre-build component and the number of commits since
  BUILD="$(( PREBUILD + COMMITS ))"
fi

VERSION="${MAJOR}.${MINOR}.${BUILD}"

# Make sure this is an annotated tag so it will get picked up by the above describe.
# See `man git-tag` for more information
git tag -a "$VERSION" -m "$VERSION"
