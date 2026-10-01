# Plan — "best" weather thermostat gadget (SwiftUI, macOS 14+)

Spec: `INSTRUCTIONS.md`. Reference screenshots: `/Users/dev/Downloads/medium/screenshots/`
(`now-page.png`, `forecast-page.png`, 900×900 px).

Work through the milestones in order, starting with CI (M0). Each one should build, run and be committed
before starting the next. Tick boxes as items land.

## Technical decisions

| Area | Choice | Why |
|---|---|---|
| Window | AppKit `NSWindow` (`.borderless`, `isOpaque = false`, `backgroundColor = .clear`) hosting SwiftUI via `NSHostingView`, created from an `NSApplicationDelegate` | `.windowStyle(.plain)` needs macOS 15, and the target is macOS 14 |
| Layout | One `GeometryReader`. Every size, offset and font is a fraction of the dial diameter `D` | Any window size keeps the same proportions |
| Arcs | Custom `Shape` with an animatable `progress`, stroked with an `AngularGradient`, round caps, glow | Shapes interpolate smoothly with `.animation(.easeOut(duration: 0.8))` |
| 3D | SceneKit `SCNView` in an `NSViewRepresentable`, transparent background | Native and needs no dependencies. RealityKit's `RealityView` needs macOS 15 |
| GLB loading | Small hand-written glTF-binary parser (`GLBLoader.swift`) → `SCNNode` tree | No Apple framework imports `.glb`, and neither Blender nor usdzconvert is installed |
| SVG icons | `NSImage(contentsOfFile:)`, already verified to load these SVGs, marked `isTemplate` and tinted white | No dependencies |
| Gestures | **One** `DragGesture` owns the pager area and locks to an axis on first movement (vertical → page, horizontal → forecast strip) | On macOS, mouse drags don't scroll a `ScrollView`, and nested recognizers fight. A single recognizer can't fight itself |
| Data | IP geolocation (`https://ipapi.co/json/`, fallback `https://ipwho.is/`) → Open-Meteo, `async/await` + `URLSession`, `@Observable` model | Free and needs no API key |
| Resources | `build.sh` copies `img/` into `MyApp.app/Contents/Resources/img`, loaded via `Bundle.main` | No Xcode project |

### Defaults chosen (change if you disagree)
- Window size is 500×500 pt, so 1000 px on Retina. Size is a single constant.
- Temperature arc range is −10 °C … 40 °C. The screenshot shows 21° at about 55% full, which fits.
- Wind arc range is 0 … 40 km/h. The screenshot shows 6 km/h at about 15% full, which fits.
- Normal window level, not always-on-top. The window can be moved by dragging the ring, and quits with ⌘Q or the right-click menu.
- Fonts are the system font for now. The original looks like Open Sans, which can be bundled later if we want it.

## Geometry reference (measured on the 900 px screenshot)

Outer ring radius is R ≈ 420 px, with the dial centre at about (432, 485). All angles below are
in screen degrees: 0° = right (3 o'clock), increasing clockwise.

| Element | Measurement | As fraction of R |
|---|---|---|
| Metallic rim | outer ~20 px band | 1.00 → ~0.95 |
| Black bezel | rim → face edge | ~0.95 → 0.73 |
| Teal face radius | ~305 px | 0.73 |
| "best" logo centre | 350 px above centre | 0.83 up |
| Wind speed text | 242 px above centre | 0.58 up |
| Compass centre | ~188 px above centre, Ø ≈ 60 px | 0.45 up, Ø 0.14 |
| Arc radius | ~228 px | 0.54 |
| Left arc (temp) | 136° → 256° (120° sweep), fills from bottom (136°) upward | |
| Right arc (wind) | mirror: 44° → −76°, fills from bottom (44°) upward | |
| Location label | 183 px below centre | 0.44 down |
| Temperature | 243 px below centre, cap height ≈ 50 px | 0.58 down |

Faint dark "track" arcs are visible behind both gauges along their full sweep.
The temperature gradient appears **fixed to the full arc** (white/mint at the bottom → green →
blue → magenta at the top), so a hot day reveals magenta at the tip. Check this against the demo.

## Milestones

### M0 — CI (GitHub Actions) — top priority
- [ ] `.github/workflows/ci.yml` on `macos-latest` (Apple Silicon), triggered on push and PR: run `./build.sh` and fail on compiler errors
- [ ] Test harness: compile the pure-logic sources (everything except the app entry point and views) with `Tests/*.swift` into a small test executable through `./test.sh` (asserts, non-zero exit on failure), and run it in CI. Switch to a SwiftPM package with a `swift-testing` target later only if the harness gets in the way
- [ ] One trivial test so the pipeline is green end to end
- [ ] **Rule from here on:** every milestone adds tests for the pure logic it introduces, and CI stays green before each commit. Use no network in tests; use recorded fixtures instead
- [ ] Optional, after M2: a smoke test that launches the app with `GADGET_MOCK=1`, checks it stays alive for a few seconds, and uploads a window screenshot as a workflow artifact

### M1 — Project plumbing
- [ ] `build.sh`: copy `img/` into `Contents/Resources/img`
- [ ] `Resources.swift`: helpers `imageURL(_:)` and `nsImage(_:)` resolving from `Bundle.main`
- [ ] Split `App.swift` into `App.swift` (entry and AppDelegate) plus view files as they appear
- [ ] `CLAUDE.md` (done with this plan)

### M2 — Borderless transparent window
- [ ] `AppDelegate` creates a borderless, clear, non-opaque `NSWindow` of size `D×D` containing `NSHostingView(GadgetView())`
- [ ] App activation policy and menu: ⌘Q works; right-click context menu with "Quit"
- [ ] Drag-to-move from the ring/bezel area only, using `window.performDrag(with:)` on mouse-down. Drags on the face belong to the pager
- [ ] Clicks in the transparent corners pass through
- [ ] Debug: with `GADGET_DEBUG=1`, print the `CGWindowID` to stdout so `screencapture -o -l <id>` can grab the window for comparison
- [ ] Debug: with `GADGET_REF=<png>`, overlay a reference screenshot at 50% opacity, scaled so its ring matches ours

### M3 — Static dial artwork
- [ ] Metallic rim: `AngularGradient` of grays for a brushed look, a linear top-light highlight and a thin dark outer edge
- [ ] Black bezel: near-black with a subtle top-left → bottom-right sheen
- [ ] Teal face: `RadialGradient` (lighter teal toward top centre, very dark at edges), a cyan-ish glow on the lower inner edge, and an inner shadow where it meets the bezel
- [ ] "best" wordmark: bold rounded sans, light-gray metallic gradient, centred on the bezel at the top
- [ ] Check side by side with `now-page.png` using `GADGET_REF`

### M4 — Arc gauges
- [ ] `ArcGauge` shape (start angle, sweep, direction, `progress` as `animatableData`)
- [ ] Full-length dark track behind each gauge
- [ ] Left arc: colour gradient (white → green → blue → magenta, bottom → top), round caps, soft glow (`.shadow` / blurred copy)
- [ ] Right arc: grayscale gradient (white at bottom → dark gray toward top)
- [ ] `.animation(.easeOut(duration: 0.8), value:)` on value changes
- [ ] Debug key, for example `R`, randomizes mock values to test the animation

### M5 — Readouts and wind compass
- [ ] Wind speed: bold number plus smaller " km/h", top centre
- [ ] `WindCompass`: `wind_rose.png` with `wind_chevron.png` on top, both template-tinted light gray. The chevron rotates by wind direction (0° = N, clockwise)
- [ ] Rotation animates along the shortest path (unwrap angles so 350° → 10° doesn't spin backwards)
- [ ] Tests: angle unwrapping and the value → arc-progress clamping (from M4)
- [ ] Location name (small, gray) above a large bold temperature with a "º" suffix
- [ ] Mock data mode (`GADGET_MOCK=1`) matching the screenshot: Vila Real, 21°, 6 km/h, ~250°, Tue 22/16, Wed 20/13 …

### M6 — Live data
- [ ] `WeatherModel` (`@Observable`, `@MainActor`) with current values (temp, wind speed, wind dir, code, isDay), location name and `[DailyForecast]`
- [ ] `LocationService`: IP geolocation → lat, lon, city (primary, then fallback provider)
- [ ] `WeatherService`: Open-Meteo request
      `current=temperature_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day`
      `&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=8&timezone=auto`
      Drop `daily[0]` (today) to keep the next 7 days
- [ ] Refresh on launch and every 10 min. On failure keep the last good data, retry sooner, and show "--" before the first success
- [ ] `WeatherCode.swift`: WMO code → icon filename, with day/night variants for the current icon and day variants for the forecast
      (0 clear · 1 few-clouds · 2 clouds · 3 many-clouds/overcast · 45/48 fog · 51–55 showers-scattered ·
      56/57 freezing-scattered-rain · 61–65 showers · 66/67 freezing-rain · 71–75 snow · 77 snow-scattered ·
      80–82 showers(-scattered) · 85/86 snow(-scattered) · 95 storm · 96/99 hail/storm · unknown → none-available)
- [ ] Wire the model into the UI. Gauges and compass animate on refresh
- [ ] Tests: decode a recorded Open-Meteo fixture (`Tests/Fixtures/`), check that today is dropped and 7 days remain, decode the IP-geo fixtures, cover the code → icon mapping and confirm every mapped SVG exists in `img/weather-icons/`

### M7 — Pager and forecast
- [ ] `PagerView`: two stacked pages in a circular area about the size of the inner arc region; `pageOffset` follows the drag
- [ ] Snap to a page on release using `predictedEndTranslation`, so a flick works. Spring animation, rubber-band past the ends
- [ ] Soft radial vignette mask over the whole pager (`RadialGradient` black → clear near the edge), not a hard clip
- [ ] Page 2: horizontal strip of 7 `DayCard`s (SVG icon, "Tue", "22º / 16º"). Card spacing matches `forecast-page.png`, with about 2 cards visible
- [ ] Horizontal free scroll with momentum (from predicted end), clamped to content bounds with a spring
- [ ] Axis lock in the single drag gesture: decide on the first ~6 pt of travel by comparing |dx| and |dy|, then keep that axis until release. Horizontal is only active on page 2
- [ ] Keep the axis-lock and snap/momentum maths in a pure type (no SwiftUI) and test it: axis decision, page snap from offset plus velocity, horizontal clamping
- [ ] Stretch: trackpad two-finger scroll through an `NSEvent` local `scrollWheel` monitor, with the same axis lock and phase-aware snapping

### M8 — 3D cloud
- [ ] `GLBLoader`: parse the GLB header, JSON chunk (`Codable`) and BIN chunk; accessors (float VEC2/VEC3, u16/u32 indices) → `SCNGeometrySource`/`SCNGeometryElement`; node TRS hierarchy (glTF and SceneKit are both Y-up, so no conversion); `baseColorFactor` materials
- [ ] Skip primitives with **no material**. They are Blender helper/boolean-cutter objects (meshes 5–8, 14, 15, 17). Check this visually
      Found during M8: the file also exports draft clouds (hidden in Blender) with the cloud material at other
      positions. Only `Icosphere.007` sits above the raindrop paths; `CloudScene` keeps that one by name
- [ ] Tests: parse `cloud.glb` and check node, mesh and animation counts, plus that material-less meshes are skipped
- [ ] Play the 6 glTF animations (raindrops falling) as looping `CAKeyframeAnimation`s on `position`
- [ ] Look: tan/cream cloud and cyan drops (override the dark-blue "water" material to match the screenshot), faceted (flat) normals
      Revised (#29): the cel bands flattened every facet to one tone. Now physically-based materials with the
      file's metallic/roughness, lit by the three Cycles point lights from `cloud.blend` (the glTF export drops
      lights), kept camera-relative, plus a generated sky as `lightingEnvironment` for soft fill. The meshes have UVs
      but no textures, so UV mapping plays no part in the look
- [ ] Camera framed from the bounding box of visible nodes, slight top-down angle, larger bump on the left as in the screenshot
- [ ] Gentle idle motion (slow bob or yaw sway)
- [ ] Embed in page 1. Confirm the SwiftUI vignette mask and page offset apply to the `SCNView`. If the mask doesn't apply, set a `CAGradientLayer` mask on the view's layer instead
- [ ] Performance: lower `preferredFramesPerSecond` and pause rendering while page 2 is showing

### M9 — Polish and fidelity pass
- [ ] Compare with both screenshots through `GADGET_REF` and adjust proportions, colours, glow, font weights and sizes
- [ ] Window shadow around the circle (or not), decided against the reference
- [ ] Remember the window position between launches (`setFrameAutosaveName`)
- [ ] Test the gesture feel: vertical swipes never move the strip, horizontal drags never change page
- [ ] Clean up debug flags and update docs

### Stretch
- [ ] Per-condition 3D models (low-poly sun, snow, storm bolt, fog) built from SceneKit primitives with flat shading, chosen by WMO code
- [ ] Bundle Open Sans for closer typography
