#!/bin/bash

# Script to update the marketing version (CFBundleShortVersionString) using agvtool
# Usage: ./xcode_version_update.sh [major|minor|patch]
# Example: ./xcode_version_update.sh minor

# Get the current directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the project root directory (parent of the script directory)
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Get the current marketing version
CURRENT_VERSION=$(agvtool what-marketing-version -terse1)

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

# Use agvtool to update the marketing version
agvtool new-marketing-version $NEW_VERSION

echo "Marketing version updated to $NEW_VERSION"

# Also reset the build number to 1 when updating the marketing version
agvtool new-version 1

echo "Build number reset to 1"

exit 0 