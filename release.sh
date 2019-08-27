#!/bin/sh
###########################################################################################################
#   Release.sh is a wrapper script around maven release plugin and git to perform a fully release flow    #
###########################################################################################################

# call this function to write to stderr
echo_stderr ()
{
    echo "$@" >&2
}

# ----------------------------------------------------------------------------------------------------------

# Release script pre-Validations for a smooth release process...
if [ "$#" -ne 2 ]; then
    echo "You must enter a release version and a next development version"
    exit 1
fi

echo "Starting BDU Commons v2 release..."

GIT_COMMIT_COMMENT_PREFIX="[Release] "

RELEASE_VERSION=$1
NEXT_DEVELOPMENT_VERSION=$2

echo "Releasing: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"

echo "git checkout master"
git checkout master
GIT_CHECKOUT_EXIT_CODE=$?
if [ "$GIT_CHECKOUT_EXIT_CODE" -ne 0 ]; then
  echo_stderr "Error '$GIT_CHECKOUT_EXIT_CODE' checking out the git's master branch"
  exit 2
fi

# 1st - Maven release prepare dry run (used to maven and git basic validations before startint the release process)
echo "mvn -B release:prepare -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX -D dryRun=true"
mvn -B release:prepare -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX" -D dryRun=true
MVN_RELEASE_PREPARE_DRY_RUN_EXIT_CODE=$?
if [ "$MVN_RELEASE_PREPARE_DRY_RUN_EXIT_CODE" -ne 0 ]; then
  echo_stderr "Error '$MVN_RELEASE_PREPARE_DRY_RUN_EXIT_CODE' when maven was executing a dry run before preparing the release"
  mvn release:clean
  exit 3
fi

# 2nd - Maven release prepare
echo "mvn -B release:prepare -Dresume=false  -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX"
mvn -B release:prepare -Dresume=false -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX"

MVN_RELEASE_PREPARE_EXIT_CODE=$?
if [ "$MVN_RELEASE_PREPARE_EXIT_CODE" -ne 0 ]; then
  echo_stderr "Error '$MVN_RELEASE_PREPARE_EXIT_CODE' when maven was preparing the release"
  mvn release:clean
  exit 4
fi

# 3rd - Maven release perform
echo "mvn -B release:perform"
mvn -B release:perform

MVN_RELEASE_PERFORM_EXIT_CODE=$?
if [ "$MVN_RELEASE_PERFORM_EXIT_CODE" -ne 0 ]; then
  echo_stderr "Error '$MVN_RELEASE_PERFORM_EXIT_CODE' when maven was performing the release"
  exit 5
fi

# 4th - Git merge to master branch

#TODO

echo "RELEASE FINISHED: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"
