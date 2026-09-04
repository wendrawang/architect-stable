#!/usr/bin/env bash
# The authoritative gates from Part 5 and Part 9.4. Requires macOS with Xcode 15+
# and SwiftLint. Run this before claiming anything in this repository builds.
set -euo pipefail
cd "$(dirname "$0")/.."

SIMULATOR="${SIMULATOR:-iPhone 15}"

echo "== swiftlint --strict =="
swiftlint --strict --config .swiftlint.yml

echo
echo "== xcodebuild build: RouterKit (device slice) =="
pushd Packages/RouterKit >/dev/null
xcodebuild -scheme RouterKit -destination 'generic/platform=iOS' build | tee ../../build.log
popd >/dev/null

echo
echo "== xcodebuild test: RouterKit =="
pushd Packages/RouterKit >/dev/null
xcodebuild -scheme RouterKit -destination "platform=iOS Simulator,name=${SIMULATOR}" test
popd >/dev/null

echo
echo "== xcodebuild build: AppCore (pulls every package) =="
pushd Packages/AppCore >/dev/null
xcodebuild -scheme AppCore -destination 'generic/platform=iOS' build
popd >/dev/null

echo
echo "== xcodebuild test: FeatureSample and AppCore =="
for package in FeatureSample AppCore; do
  pushd "Packages/${package}" >/dev/null
  xcodebuild -scheme "${package}" -destination "platform=iOS Simulator,name=${SIMULATOR}" test
  popd >/dev/null
done

echo
echo "== swiftlint analyze --strict =="
swiftlint analyze --strict --config .swiftlint.yml --compiler-log-path build.log

echo
echo "== structural checks =="
bash Tools/verify.sh

echo
echo "All gates passed."
