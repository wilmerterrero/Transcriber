#!/bin/bash

# Script to update the marketing version (CFBundleShortVersionString)
# Usage: ./update_version.sh [major|minor|patch]
# Example: ./update_version.sh minor

# Get the current directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the project root directory (parent of the script directory)
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Path to the project.pbxproj file
PROJECT_PBXPROJ="$PROJECT_DIR/GPSCam.xcodeproj/project.pbxproj"

# Get the current marketing version from the project file
CURRENT_VERSION=$(grep -A 1 "MARKETING_VERSION" "$PROJECT_PBXPROJ" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\|[0-9]\+\.[0-9]\+' | head -1)

# If no version is found, start with 1.0.0
if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="1.0.0"
fi

# Split the version into components
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"

# Ensure we have at least 3 parts (major.minor.patch)
if [ ${#VERSION_PARTS[@]} -eq 2 ]; then
    VERSION_PARTS+=("0")
fi

MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]:-0}

# Determine which part to increment based on the argument
INCREMENT_TYPE=${1:-"patch"}

case $INCREMENT_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Invalid increment type. Use 'major', 'minor', or 'patch'."
        exit 1
        ;;
esac

# Construct the new version
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Updating version from $CURRENT_VERSION to $NEW_VERSION"

# Use sed to update the marketing version in the project.pbxproj file
sed -i '' "s/MARKETING_VERSION = [0-9]*\.[0-9]*\(\.[0-9]*\)\{0,1\};/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT_PBXPROJ"

echo "Marketing version updated to $NEW_VERSION"

# Also reset the build number to 1 when updating the marketing version
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = 1;/g" "$PROJECT_PBXPROJ"

echo "Build number reset to 1"

exit 0 