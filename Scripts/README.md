# Version and Build Number Scripts

This directory contains scripts to manage version and build numbers for the GPSCam app.

## Automatic Build Number Increment

There are two options for automatically incrementing the build number:

### Option 1: Using agvtool (Recommended)

The `xcode_increment_build.sh` script uses Apple's built-in `agvtool` to increment the build number, which works better with Xcode's sandbox restrictions.

#### Setup in Xcode

1. First, enable versioning in your project:
   - Select your project in the Project Navigator
   - Select your target
   - Go to the "Build Settings" tab
   - Search for "versioning"
   - Set "Current Project Version" to "1" (or your current build number)
   - Set "Versioning System" to "Apple Generic"

2. Add a Run Script Build Phase:
   - Select your target
   - Go to the "Build Phases" tab
   - Click the "+" button in the top-left corner of the Build Phases section
   - Select "New Run Script Phase"
   - Drag this new Run Script phase to be just before the "Copy Bundle Resources" phase
   - Expand the Run Script section
   - In the script text area, add the following:

```bash
"${SRCROOT}/.scripts/xcode_increment_build.sh"
```

### Option 2: Using Custom Script (May have sandbox issues)

The `increment_build_number.sh` script directly modifies the project.pbxproj file to increment the build number. This approach may encounter sandbox restrictions in Xcode.

If you encounter a sandbox error like:
```
Sandbox: bash(xxxxx) deny(1) file-read-data /path/to/increment_build_number.sh
```

You can either:
1. Add the script directly to your Xcode project (not just in the .scripts folder)
2. Use Option 1 with agvtool instead

#### Setup in Xcode (if adding to project)

1. In Xcode, right-click on your project in the Project Navigator
2. Select "Add Files to 'GPSCam'..."
3. Navigate to your `.scripts` folder and select `increment_build_number.sh`
4. Make sure "Copy items if needed" is checked
5. Click "Add"
6. In your Run Script build phase, use:
   ```bash
   "${SRCROOT}/increment_build_number.sh"
   ```

## Manual Version Update

The `update_version.sh` script allows you to update the marketing version (CFBundleShortVersionString) when preparing for a new release.

### Usage

```bash
# Update patch version (1.0.0 -> 1.0.1)
./.scripts/update_version.sh patch

# Update minor version (1.0.1 -> 1.1.0)
./.scripts/update_version.sh minor

# Update major version (1.1.0 -> 2.0.0)
./.scripts/update_version.sh major
```

When you update the marketing version, the build number is automatically reset to 1.

### Using agvtool for Version Updates

You can also use agvtool to update the marketing version:

```bash
# Set the marketing version
agvtool new-marketing-version 1.2.3
```

## Displaying Version and Build Number

To display the version and build number in your app, use:

```swift
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
```

Example: "Version 1.0 (42)" 