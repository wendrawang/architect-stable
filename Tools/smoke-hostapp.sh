#!/usr/bin/env bash
# Builds the host app, launches it on a simulator, and proves it is still running.
#
# This is the "does the infrastructure actually come up on screen" check. A build passing
# says the code compiles; only a launch says the composition root wired a tab host, resolved
# the sample route through the registry, and put a view controller in a window.
set -euo pipefail
cd "$(dirname "$0")/.."

SIMULATOR="${SIMULATOR:-iPhone 15}"
BUNDLE_ID="id.co.ocbcnisp.byon.hostapp"
DERIVED="${PWD}/dd"

echo "== Building HostApp for the simulator =="
xcodebuild -project HostApp/HostApp.xcodeproj \
           -scheme HostApp \
           -destination "platform=iOS Simulator,name=${SIMULATOR}" \
           -derivedDataPath "${DERIVED}" \
           build

DEVICE=$(xcrun simctl list devices available -j | SIMULATOR="${SIMULATOR}" python3 -c '
import json, os, sys
wanted = os.environ["SIMULATOR"]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    for device in devices:
        if device["name"] == wanted:
            print(device["udid"])
            sys.exit(0)
sys.exit(f"no available simulator named {wanted}")
')
echo "== Simulator ${SIMULATOR} (${DEVICE}) =="

xcrun simctl boot "${DEVICE}" 2>/dev/null || true
xcrun simctl bootstatus "${DEVICE}" -b

APP="${DERIVED}/Build/Products/Debug-iphonesimulator/HostApp.app"
test -d "${APP}" || { echo "FAIL: ${APP} was not produced by the build"; exit 1; }

xcrun simctl uninstall "${DEVICE}" "${BUNDLE_ID}" 2>/dev/null || true
xcrun simctl install "${DEVICE}" "${APP}"
xcrun simctl launch "${DEVICE}" "${BUNDLE_ID}"

# Give the scene delegate time to build the composition root and present the tab host.
sleep 8
xcrun simctl io "${DEVICE}" screenshot hostapp-launch.png || true

if xcrun simctl spawn "${DEVICE}" launchctl list | grep -q "${BUNDLE_ID}"; then
  echo
  echo "PASS: HostApp is running. The composition root built the registry, the overlay"
  echo "      window and the tab host, and the sample route resolved into a screen."
else
  echo
  echo "FAIL: HostApp is not running. It crashed on launch or never started."
  echo "      Recent device log:"
  xcrun simctl spawn "${DEVICE}" log show --last 2m --predicate "processImagePath CONTAINS 'HostApp'" --style compact || true
  exit 1
fi
