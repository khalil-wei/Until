#!/bin/sh
set -eu

PROJECT="apps/ios/CountdownEvents.xcodeproj"
SCHEME="CountdownEvents"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode first." >&2
  exit 1
fi

if [ ! -d "$PROJECT" ]; then
  echo "$PROJECT not found. Run this script from the repository root." >&2
  exit 1
fi

echo "== Xcode version =="
xcodebuild -version

echo
echo "== Project schemes =="
xcodebuild -list -project "$PROJECT"

echo
echo "== Debug build =="
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build

echo
echo "Debug build completed."
