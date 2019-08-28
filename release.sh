#!/bin/sh
###########################################################################################################
#   release.sh is a wrapper script around maven release plugin and git to perform a fully release flow    #
#   with minimal human interaction.                                                                       #
###########################################################################################################

# ---------------------------------------------- Utilities ------------------------------------------------

# Terminal ANSI colors codes.
RED='\033[0;31m'
NC='\033[0m'      # No Color

# Write all arguments to stderr
echo_stderr ()
{
  echo -e "${RED}" >&2
  echo "################################ Release Script ######################################" >&2
  echo  "$@" >&2
  echo "######################################################################################" >&2
  echo -e "${NC}" >&2
}

# echo something with a div
echo_div ()
{
  echo "################################ Release Script ######################################"
  echo "$1"
  echo "######################################################################################"
}

# ----------------------------------------------------------------------------------------------------------

# ------------------------ Release script validations for a smooth release process... ----------------------

if [ "$#" -ne 2 ]; then
    echo "You must enter a release version (e.g. 1.2.1) and a next development version (e.g. 1.3.0-SNAPSHOT)"
    exit 1
fi

#------------------------------------------ Release Workflow -----------------------------------------------
echo_div "Starting BDU Commons v2 release..."

GIT_COMMIT_COMMENT_PREFIX="[Release] "

RELEASE_VERSION=$1
NEXT_DEVELOPMENT_VERSION=$2

echo_div "Releasing Version: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"

# 1st - Git checkout feature/developmebt branch, where releases are performed.
echo_div "git checkout feature/development"
git checkout feature/development
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' checking out the git's feature/development branch. SAFE to retry release."
  exit 2
fi

# 2nd - Maven release prepare dry run (used to maven and git run basic validations before starting the release process)
echo_div "mvn -B release:prepare -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX -D dryRun=true"
mvn -B release:prepare -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX" -D dryRun=true
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was executing a dry run before preparing the release. SAFE to retry release."
  mvn release:clean # Clean release temporary resources that are not necessary
  exit 3
fi

# 3rd - Maven release prepare. Built/Test project, commit, tag and push the project into git.
echo_div "mvn -B release:prepare -Dresume=false  -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION -D scmCommentPrefix=$GIT_COMMIT_COMMENT_PREFIX"
mvn -B release:prepare -Dresume=false -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION" -D scmCommentPrefix="$GIT_COMMIT_COMMENT_PREFIX"
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was preparing the release. SAFE to retry release."
  mvn release:clean # Clean release temporary resources that are not necessary
  exit 4
fi

# 4th - Maven release perform. Deploy the artifacts and documentation to the remote servers/repositories.
echo_div "mvn -B release:perform"
mvn -B release:perform
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' when maven was performing the release. Release was rolledback. CAREFUL retrying the release check git and maven state."
  mvn release:rollback # Rollback the release restoured project and git to the previous state
  exit 5
fi

# 5th - Git checkout master branch.
echo_div "git checkout master"
git checkout master
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' checking out the git master branch. DO NOT retry release, update master manually."
  exit 6
fi

# 6th - Git merge feature/development to master branch.
# Merge the feature/development into master in order to receive the release.
echo_div "git merge feature/development"
git merge feature/development
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' merging feature/development branch into master. DO NOT retry release, metge to master and push manually."
  exit 7
fi

# 7th - Git merge push to master branch. Update the remote master branch with the merged release.
echo_div "git push master"
git push master
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE ERROR '$?' merging feature/development branch into master. DO NOT retry release, push to master manually."
  exit 8
fi

# 8th - Git heckout feature/development in order to return the git to the branch.
echo_div "git checkout feature/development"
git checkout feature/development
if [ $? -ne 0 ]; then
  echo_stderr "RELEASE WARNING '$?' merging feature/development branch into master. Release was finished only the last feature/development checkout failed."
  exit 9
fi

echo "RELEASE FINISHED: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"
#------------------------------------------ Release finished -----------------------------------------------
