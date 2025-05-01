#!/bin/bash

PBXPROJ_FILE="KeyRest.xcodeproj/project.pbxproj"

# Check if file exists
if [ ! -f "$PBXPROJ_FILE" ]; then
  echo "Error: $PBXPROJ_FILE not found!"
  exit 1
fi

# Check if project is valid
plutil -lint "$PBXPROJ_FILE"
if [ $? -ne 0 ]; then
  echo "Error: Project file is invalid. Fix before continuing."
  exit 1
fi

# Downgrade objectVersion safely
sed -i '' 's/objectVersion = 77;/objectVersion = 56;/' "$PBXPROJ_FILE"

echo "✅ Downgraded objectVersion successfully!"