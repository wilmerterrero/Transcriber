#!/bin/bash

# Script to increment build number in Xcode project
# To be used as a Run Script Build Phase in Xcode

# Get the current directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the project root directory (parent of the script directory)
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Path to the Info.plist (using PlistBuddy to modify)
PLIST_BUDDY="/usr/libexec/PlistBuddy"
PROJECT_PBXPROJ="$PROJECT_DIR/GPSCam.xcodeproj/project.pbxproj"

# Get the current build number from the project file
CURRENT_BUILD_NUMBER=$(grep -A 1 "CURRENT_PROJECT_VERSION" "$PROJECT_PBXPROJ" | grep -o '[0-9]\+' | head -1)

# If no build number is found, start with 1
if [ -z "$CURRENT_BUILD_NUMBER" ]; then
    CURRENT_BUILD_NUMBER=1
else
    # Increment the build number
    CURRENT_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
fi

echo "Incrementing build number to $CURRENT_BUILD_NUMBER"

# Use sed to update the build number in the project.pbxproj file
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $CURRENT_BUILD_NUMBER;/g" "$PROJECT_PBXPROJ"

echo "Build number updated to $CURRENT_BUILD_NUMBER"

exit 0 