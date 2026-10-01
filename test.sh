#!/bin/sh
# Builds and runs the logic tests. Usage: ./test.sh
# Compiles the pure-logic sources (everything in Sources/ except the app entry
# point and views) together with Tests/*.swift into build/tests/LogicTests.
# Excluded: App.swift, *View.swift, *Views.swift. Keep logic out of those files.
set -e
cd "$(dirname "$0")"

OUT=build/tests
mkdir -p "$OUT"

LOGIC=""
for f in Sources/*.swift; do
    case "$(basename "$f")" in
        App.swift|*View.swift|*Views.swift) ;;
        *) LOGIC="$LOGIC $f" ;;
    esac
done

# Tests/main.swift is the entry point, so no -parse-as-library here.
# shellcheck disable=SC2086
swiftc -target arm64-apple-macos14 $LOGIC Tests/*.swift -o "$OUT/LogicTests"
"$OUT/LogicTests"
