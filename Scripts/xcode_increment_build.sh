#!/bin/bash

# Script to increment build number in Xcode project using agvtool
# To be used as a Run Script Build Phase in Xcode

# This script uses Apple's agvtool which is designed to work with Xcode's build system
# and doesn't have sandbox restrictions

# Increment the build number
cd "${SRCROOT}"
agvtool next-version -all

echo "Build number incremented using agvtool"

exit 0 