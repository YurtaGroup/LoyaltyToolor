#!/bin/bash
# Deploy TOOLOR app to iPhone wirelessly (no cable needed)
# Usage: ./deploy_iphone.sh [debug|release]

set -e

MODE="${1:-debug}"
DEVICE="7BFCA6B0-58BE-53F1-A869-96CFFC1BB97D"  # iPhone Эмес (iPhone 17 Pro Max)
BUNDLE_ID="com.toolor.toolorApp"

echo "Building Flutter iOS ($MODE)..."
if [ "$MODE" = "release" ]; then
    flutter build ios --release
else
    flutter build ios --debug
fi

echo "Installing on iPhone..."
xcrun devicectl device install app --device "$DEVICE" build/ios/iphoneos/Runner.app

echo "Launching..."
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" 2>/dev/null || echo "Unlock your iPhone to open the app!"

echo "Done!"
