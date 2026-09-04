#!/usr/bin/env bash
# Portable structural verification.
#
# The authoritative gate is Part 5 of the brief:
#   xcodebuild -scheme RouterKit -destination 'generic/platform=iOS' build
#   xcodebuild -scheme RouterKit -destination 'platform=iOS Simulator,name=iPhone 15' test
#   swiftlint --strict --config .swiftlint.yml
#   swiftlint analyze --strict --compiler-log-path build.log
# All four need macOS with Xcode. This script is what can be checked without it.
set -uo pipefail
cd "$(dirname "$0")/.."

FAILURES=0
SOURCES=$(find Packages -path '*/Sources/*' -name '*.swift' | sort)

check_absent() {
  local label="$1" pattern="$2"
  shift 2
  local hits
  hits=$(grep -nE "$pattern" $SOURCES "$@" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "FAIL  $label"
    echo "$hits" | sed 's/^/        /'
    FAILURES=$((FAILURES + 1))
  else
    echo "ok    $label"
  fi
}

echo "== Part 5 confirmations =="
check_absent "No AnyView in any file" '\bAnyView\b'
check_absent "No banned iOS 16 API" '\b(NavigationStack|NavigationSplitView|navigationDestination|presentationDetents|presentationDragIndicator|ShareLink|GridRow|ViewThatFits|AnyLayout|scrollDisabled|sizingOptions|Observable\(\)|fontDesign)\b'
check_absent "No legacy SwiftUI navigation" '\b(NavigationView|NavigationLink|fullScreenCover)\b'
check_absent "No Coordinator type" '(class|struct|protocol)[[:space:]]+[A-Za-z]*Coordinator\b'
check_absent "No force unwrap / try! / as!" '(try!|as!|\)!\.| as! )'
check_absent "No banned type suffix" '(class|struct)[[:space:]]+[A-Za-z]+(Manager|Helper|Provider|Facade|Wrapper)\b'
check_absent "No completion-handler parameter names" '\b(completion|handler|callback|block)[[:space:]]*:[[:space:]]*(@escaping[[:space:]]+)?\('

AVAIL=$(grep -rnE 'if[[:space:]]+#available' $SOURCES 2>/dev/null | grep -v 'Compat/AvailabilityShim.swift' || true)
if [ -n "$AVAIL" ]; then
  echo "FAIL  No 'if #available' outside AvailabilityShim.swift"
  echo "$AVAIL" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "ok    No 'if #available' outside AvailabilityShim.swift"
fi

SINGLETON=$(grep -rnE 'static[[:space:]]+(let|var)[[:space:]]+shared\b' $SOURCES 2>/dev/null || true)
SINGLETON=$(echo "$SINGLETON" | grep -v 'LifecycleTracker.swift' || true)
if [ -n "$SINGLETON" ]; then
  echo "FAIL  No singletons outside the DEBUG-only LifecycleTracker"
  echo "$SINGLETON" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "ok    No singletons outside the DEBUG-only LifecycleTracker"
fi

echo
echo "== Package dependency edges =="
for manifest in Packages/*/Package.swift; do
  package=$(basename "$(dirname "$manifest")")
  case "$package" in
    Feature*)
      if grep -qE '\.\./(AppCore|Feature)' "$manifest"; then
        echo "FAIL  $package depends on AppCore or another feature"
        FAILURES=$((FAILURES + 1))
      else
        echo "ok    $package depends on no feature and not on AppCore"
      fi
      ;;
    CoreKit)
      if grep -q '\.package(path:' "$manifest"; then
        echo "FAIL  CoreKit has dependencies"
        FAILURES=$((FAILURES + 1))
      else
        echo "ok    CoreKit depends on nothing"
      fi
      ;;
  esac
done
IMPORTS=$(grep -rnE '^import (AppCore|Feature)' Packages/*/Sources 2>/dev/null | grep -v '^Packages/AppCore/' || true)
if [ -n "$IMPORTS" ]; then
  echo "FAIL  A non-AppCore package imports AppCore or a feature"
  echo "$IMPORTS" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "ok    Only AppCore imports a feature package"
fi

echo
echo "== Defaulted dependency parameters =="
DEFAULTS=$(grep -rnE '(navigator|registry|logger|analytics|snackbar|repository|useCase|dependencies|overlay|session)[[:space:]]*:[[:space:]]*(any[[:space:]]+)?[A-Za-z<>\[\], ]+[[:space:]]*=[^=]' $SOURCES 2>/dev/null || true)
if [ -n "$DEFAULTS" ]; then
  echo "FAIL  A dependency parameter has a default value"
  echo "$DEFAULTS" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "ok    No default value on any dependency parameter"
fi

echo
echo "== DTO containment =="
DTO=$(grep -rnE '\bPinVerificationDTO\b|\b[A-Za-z]+DTO\b' Packages/*/Sources 2>/dev/null | grep -v '/Data/' || true)
if [ -n "$DTO" ]; then
  echo "FAIL  A DTO type is referenced outside Data/"
  echo "$DTO" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "ok    No DTO referenced outside Data/"
fi

echo
python3 Tools/lint_custom_rules.py || FAILURES=$((FAILURES + 1))
echo
python3 Tools/budgets.py || FAILURES=$((FAILURES + 1))

echo
echo "structural failures: $FAILURES"
exit $((FAILURES > 0 ? 1 : 0))
