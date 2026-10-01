# Exercise (Medium mode)

Recreate the app you just saw demoed live, using the description below and
the provided assets in `assets/`. Use any language/framework/AI assistant
you like — this is not tied to any particular tech stack.

**Objective: get as close as possible to what you saw in the demo.** The
screenshots (`screenshots/now-page.png`, `screenshots/forecast-page.png`)
are a static backup reminder of two moments from it — useful for double
checking layout/proportions/colors, but the live demo (motion, gesture
feel, real data updating) is the actual target. The written description
below exists to help you nail down details the demo/screenshots alone
can't fully convey, not to replace either of them.

## Overview

A small, borderless, transparent-background desktop "gadget" (no window
chrome/title bar needed — just the circular widget itself) that looks like a
smart-thermostat dial, showing the current weather for the user's location.
Roughly square/circular, e.g. ~1000x1000 px at 1x, but any size that keeps
the same proportions is fine.

## Layout (see screenshots)

From outside in:
1. A metallic circular ring/bezel.
2. Inside it, a dark circular face with a teal/blue-green radial-gradient
   background.
3. A "best" wordmark logo centered at the top, sitting on the ring.
4. Two thin arc gauges just inside the ring:
   - **Left arc**: a colorful gradient stroke (roughly magenta → blue →
     green → white along its length) representing **current temperature**.
     It's empty/short at a cold minimum temperature and fills up towards a
     hot maximum.
   - **Right arc**: the mirror shape of the left one, but a grayscale
     gradient (dark gray → white), representing **current wind speed**,
     empty at 0 and full at some reasonable max (e.g. 40 km/h).
   - Both arcs animate smoothly (ease-out, ~0.8s) whenever the underlying
     value changes, rather than jumping.
5. Near the top of the face, centered: **wind speed readout** — a bold
   number followed by a smaller " km/h" unit.
6. Directly below that: a small **wind-direction compass rose** — a circle
   with a gap at the top where an "N" letter sits, and a chevron/arrow shape
   inside that rotates smoothly to point in the current wind direction
   (0° = North = pointing at the "N" gap, increasing clockwise, standard
   meteorological "wind direction" convention — the compass artwork for this
   is provided in `assets/wind_rose.png` + `assets/wind_chevron.png`, both
   white silhouettes with alpha you can tint to any color and overlay/rotate
   the chevron on top of the circle).
7. Centered in the middle of the face: an icon for the **current weather
   condition**. **This must be an actual 3D-rendered model** (real geometry
   with lighting/shading — WebGL/three.js, a game engine, native 3D APIs,
   etc. all count), not a flat 2D image or SVG. The original uses a single
   chunky, faceted, low-poly cloud model (with small teardrop raindrops
   underneath, tan/cream toon-shaded material) shown regardless of the
   actual condition — the actual model is provided in
   `assets/3d-icon-reference/` (`cloud.blend` / `cloud.glb`, see below). You
   can reuse that same "always a cloud" approach with the provided model,
   author your own simple 3D weather shape(s), or (bonus/stretch goal) build
   a small set of 3D models, one per weather condition.
8. Near the bottom: the **location name** (small, gray) directly above a
   large, bold **current temperature** reading with a "º" suffix.

## Interaction

The circular content area in the middle (where the current-condition icon
sits) is a **2-page vertical pager** that snaps fully to one page or the
other (no partial in-between resting state):

- **Page 1 (default)**: the current-condition icon, as described above.
- **Page 2** (reveal by dragging/swiping up): a **7-day forecast** list that
  scrolls **horizontally** (drag left/right, free-scrolling, no snapping
  needed) through day cards. Each card shows: a small weather icon for that
  day (from `assets/weather-icons/`, one SVG per condition — see filenames),
  the abbreviated day name (e.g. "Tue"), and "max° / min°" text. Show the
  next 7 days starting **tomorrow** (skip today).
- Whichever page is showing, both pages are masked into the same circular
  area with a soft radial vignette (content fades near the circle's edge,
  it isn't a hard clip) — see the screenshots for the look.
- **Known tricky bit / bonus challenge**: because the vertical page-swipe and
  the horizontal forecast-swipe are nested, naively implementing both often
  causes one gesture to steal/interfere with the other. Getting this to feel
  right (vertical swipe never fighting the horizontal forecast scroll) is a
  worthwhile stretch goal, not a strict requirement.

## Data

- Get **real, live weather data** for the user's current location, with
  **automatic location detection** (no manual city entry) — e.g. resolve
  location via IP-based geolocation, then query a free weather API (no key
  required) such as Open-Meteo (`https://api.open-meteo.com/v1/forecast`)
  for current conditions + an 8-day daily forecast. Any equivalent free API
  is fine.
- Needed current values: temperature (°C), wind speed (km/h), wind direction
  (degrees), and a weather condition code to pick an icon.
- Needed daily forecast values (next 7 days): max temp, min temp, and a
  weather condition code per day.
- Refresh periodically (e.g. every 10 minutes) plus once on startup.

## Assets provided

- `assets/weather-icons/*.svg` — a full symbolic weather-icon set (clear,
  cloudy, rain, snow, storm, fog, etc., day variants). Pick the closest
  match for whatever weather-code-to-condition mapping you implement; exact
  filenames aren't prescriptive, use whichever fits each condition.
- `assets/wind_rose.png` — the compass circle-with-gap-for-"N" artwork.
- `assets/wind_chevron.png` — the direction chevron/arrow artwork (rotate
  this around the circle's center based on wind direction).
- `assets/3d-icon-reference/` — the actual 3D mesh for the mandatory 3D icon
  (see requirement above): `cloud.blend` (the original Blender source file,
  editable in Blender), `cloud.glb` (the same model exported to
  self-contained glTF/GLB — importable directly into three.js, Babylon.js,
  Unity, Godot, Blender, or basically any 3D engine/library without needing
  Blender itself), and `preview-render.png` (a quick-look render of what it
  looks like). Use this model as-is, modify it, or replace it with your own
  3D geometry — the requirement is that *something* 3D gets rendered there.
