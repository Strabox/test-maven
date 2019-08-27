###########################################################################################################
#   Release.sh is a wrapper script around maven release plugin and git to perform a fully release flow    #
###########################################################################################################

# Pre-Validations for a smooth release process...
if [ "$#" -ne 2 ]; then
    echo "You must enter a release version and a next development version"
    exit 1
fi


echo "Starting BDU Commons v2 release..."

RELEASE_VERSION=$1
NEXT_DEVELOPMENT_VERSION=$2

echo "Releasing: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"

# Maven release prepare
echo "mvn -B release:prepare -D releaseVersion=$RELEASE_VERSION -D developmentVersion=$NEXT_DEVELOPMENT_VERSION"
mvn -B release:prepare -D releaseVersion="$RELEASE_VERSION" -D developmentVersion="$NEXT_DEVELOPMENT_VERSION"

MVN_RELEASE_PREPARE_EXIT_CODE=$?
if [ "$MVN_RELEASE_PREPARE_EXIT_CODE" -ne 0 ]; then
  echo "Error '$MVN_RELEASE_PREPARE_EXIT_CODE' when maven was preparing the release"
  exit 2
fi

# Maven release perform
echo "mvn -B release:perform"
mvn -B release:perform

MVN_RELEASE_PERFORM_EXIT_CODE=$?
if [ "$MVN_RELEASE_PERFORM_EXIT_CODE" -ne 0 ]; then
  echo "Error '$MVN_RELEASE_PERFORM_EXIT_CODE' when maven was performing the release"
  exit 3
fi

# Git merge to master branch

#TODO

echo "RELEASE FINISHED: '$RELEASE_VERSION' -> Next Dev Version: '$NEXT_DEVELOPMENT_VERSION'"
