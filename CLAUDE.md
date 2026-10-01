# CLAUDE.md

Borderless, transparent macOS desktop gadget that looks like a smart-thermostat dial and shows
live weather. It has a metallic ring, a teal face, temperature and wind arc gauges, a wind compass,
a 3D cloud, and a swipe-up 7-day forecast. The full spec is in `INSTRUCTIONS.md`.

**Read `PLAN.md` first.** It has the technical decisions, measured geometry and milestone TODOs.
Work incrementally: one milestone or item at a time, then tick it in `PLAN.md`.

## Build and run

```sh
./build.sh        # → build/MyApp.app (swiftc, no Xcode project)
./build.sh run    # build and open
```

- Plain `swiftc -parse-as-library Sources/*.swift`, target `arm64-apple-macos14`. New `.swift` files in `Sources/` are picked up automatically.
- Use only Apple frameworks (SwiftUI, AppKit, SceneKit, Foundation). Don't add third-party dependencies.
- Assets live in `img/`. `build.sh` copies them into `Contents/Resources/img`, and code loads them through `Bundle.main`, never from repo paths.
- `./test.sh` runs the logic tests (PLAN.md M0); CI runs both build and tests on every push and PR.
- Kill a running instance before relaunching: `pkill -x MyApp`.

## Visual verification

Reference screenshots (900×900, outside the repo): `/Users/dev/Downloads/medium/screenshots/now-page.png`
and `forecast-page.png`. The live demo, with its motion and gesture feel, is the real target; the screenshots are a backup.

Debug environment variables (see PLAN.md M2/M5; available once implemented):
- `GADGET_DEBUG=1` prints the window's `CGWindowID`, so the window can be captured with `screencapture -o -l <id> /path/out.png`
- `GADGET_REF=<png>` overlays a reference screenshot at 50% opacity
- `GADGET_MOCK=1` uses fixed data matching the screenshots (Vila Real, 21°, 6 km/h)

Launch with env vars by running the binary directly: `GADGET_MOCK=1 build/MyApp.app/Contents/MacOS/MyApp &`.
After visual changes, capture the window and compare it against the reference before calling it done.

## Conventions

- Everything is sized relative to the dial diameter `D`. Never hard-code points in views, except for the single window-size constant.
- One responsibility per file in `Sources/` (e.g. `ArcGauge.swift`, `WindCompass.swift`, `PagerView.swift`, `CloudSceneView.swift`, `GLBLoader.swift`, `WeatherService.swift`, `WeatherCode.swift`).
- Value changes that the user sees (gauges, compass) animate with ease-out at about 0.8 s.
- The pager area uses a single drag gesture with axis locking. Don't nest a `ScrollView` inside another gesture.
- Keep logic (decoding, mapping, gesture maths, GLB parsing) out of views so it is testable. Add tests along with the logic.
- Networking uses `async/await`. UI state lives in an `@MainActor @Observable` model.

## Git

The repo is managed with **git-loom** (integration branch `integration`). Use `git loom ... --agent`
for commits and history edits. Don't use raw `git commit`, `rebase` or `amend`. Keep unrelated changes in separate commits.
