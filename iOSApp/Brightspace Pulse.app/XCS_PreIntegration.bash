#!/bin/bash
# Pre-Integration Script to increment Build Number before building.

export LANG=en_CA.UTF-8

# Note: This is NOT done generically, i.e. the relative path of the Info.plist file within the Xcode Server Source Directory is hard coded.  It will need to be changed if the file is moved, if an intermediate directory is renamed, or if this script is reused for a diferent project.
INFOPLIST_FILE="${XCS_SOURCE_DIR}/ios-notifications/BrightSpace Pulse/SupportingFiles/Info.plist"

buildNumber=${XCS_INTEGRATION_NUMBER}
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFOPLIST_FILE"

echo "Incremented Build Number to ${buildNumber}."

cd "${XCS_SOURCE_DIR}/ios-notifications/"
pod install

if [ $? -ne 0 ]
then
    echo "error: CocoaPods install failed during pre-integration script!"
    exit 1
fi

#End of Script
