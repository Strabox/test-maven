#!/bin/sh
###########################################################################################################
#   Release.sh is a wrapper script around maven release plugin and git to perform a fully release flow    #
###########################################################################################################

# Write all arguments to stderr
echo_stderr ()
{
    echo "$@" >&2
}

# ----------------------------------------------------------------------------------------------------------

# ------------------------ Release script validations for a smooth release process... ----------------------
if [ "$#" -ne 2 ]; then
    echo "You must enter a release version (e.g. 1.2.1) and a next development version (e.g. 1.3.0-SNAPSHOT)"
    exit 1
fi

#------------------------------------------ Release workflow -----------------------------------------------
echo "Starting BDU Commons v2 release..."

GIT_COMMIT_COMMENT_PREFIX="[Release] "

RELEASE_VERSION=$1
NEXT_DEVELOPMENT_VERSION=$2

echo "Releasing: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"

# 1st - Git checkout feature/developmebt branch, where releases are performed.
echo "git checkout feature/development"
git checkout feature/developmen
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' checking out the git's feature/development branch"
  exit 2
fi

# 2nd - Maven release prepare dry run (used to maven and git basic validations before startint the release process)
echo "mvn -B release:prepare -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX -D dryRun=true"
mvn -B release:prepare -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX" -D dryRun=true
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was executing a dry run before preparing the release"
  mvn release:clean
  exit 3
fi

# 3rd - Maven release prepare
echo "mvn -B release:prepare -Dresume=false  -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX"
mvn -B release:prepare -Dresume=false -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX"
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was preparing the release"
  mvn release:clean
  exit 4
fi

# 4th - Maven release perform
echo "mvn -B release:perform"
mvn -B release:perform
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was performing the release"
  exit 5
fi

# 5th - Git checkout master branch

echo "git checkout master"
git checkout master
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' checking out the git's master branch"
  exit 2
fi

# 6th - Git merge to master branch

echo "git merge feature/development"
git merge feature/development
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' merging feature/development branch into master"
  exit 2
fi

echo "RELEASE FINISHED: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"
#------------------------------------------ Release finished -----------------------------------------------
