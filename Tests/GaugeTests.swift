func runGaugeTests() {
    let t = GaugeScale.temperature
    check(t.progress(for: -10) == 0, "temp lower bound is 0")
    check(t.progress(for: 40) == 1, "temp upper bound is 1")
    check(abs(t.progress(for: 21) - 0.62) < 1e-9, "21° is 62%")
    check(t.progress(for: -50) == 0, "below range clamps to 0")
    check(t.progress(for: 99) == 1, "above range clamps to 1")
    check(t.progress(for: .nan) == 0, "NaN is 0")
    check(GaugeScale.wind.progress(for: 6) == 0.15, "6 km/h is 15%")
    check(GaugeScale.wind.progress(for: 80) == 1, "wind clamps to 1")

    check(ArcSpec.left.end == 256, "left arc ends at 256°")
    check(ArcSpec.right.end == -76, "right arc ends at -76°")
    check(ArcSpec.left.angle(at: 0.5) == 196, "left midpoint")
    check(ArcSpec.right.angle(at: 0.5) == -16, "right midpoint")
    check(ArcSpec.left.angle(at: 2) == 256 && ArcSpec.left.angle(at: -1) == 136, "angle clamps progress")

    check(t.progress(for: .infinity) == 1 && t.progress(for: -.infinity) == 0, "infinities clamp")
    check(GaugeScale(lowerBound: 5, upperBound: 5).progress(for: 5) == 0, "degenerate scale is 0")

    check(ArcSpec.left.gradientRange == 136...256 && !ArcSpec.left.reversesColors, "left gradient runs clockwise")
    check(ArcSpec.right.gradientRange == -76...44 && ArcSpec.right.reversesColors, "right gradient is reversed")

    var arc = ArcGauge(spec: .left, radius: 10, progress: 0.25)
    arc.animatableData = 0.75
    check(arc.progress == 0.75, "animatable data sets progress")

    check(!DebugOptions(environment: [:]).debugKeys, "debug keys off by default")
    check(DebugOptions(environment: ["GADGET_DEBUG": "1"]).debugKeys, "GADGET_DEBUG enables debug keys")
    check(DebugOptions(environment: ["GADGET_MOCK": "1"]).debugKeys, "GADGET_MOCK enables debug keys")
}

func runReadoutTests() {
    check(CompassAngle.unwrapped(from: 350, to: 10) == 370, "350° → 10° goes forward through north")
    check(CompassAngle.unwrapped(from: 10, to: 350) == -10, "10° → 350° goes backward through north")
    check(CompassAngle.unwrapped(from: 0, to: 180) == 180, "exactly opposite stays positive")
    check(CompassAngle.unwrapped(from: 370, to: 350) == 350, "unbounded current is handled")
    check(CompassAngle.unwrapped(from: -10, to: 10) == 10, "negative current crosses north forward")
    check(CompassAngle.unwrapped(from: 100, to: 100) == 100, "same angle does not move")
    check(CompassAngle.unwrapped(from: 100, to: 460) == 100, "full turn is no movement")
    check(CompassAngle.unwrapped(from: 100, to: .nan) == 100, "NaN target keeps the rotation")
    check(CompassAngle.normalized(370) == 10 && CompassAngle.normalized(-10) == 350, "normalized wraps")
    check(CompassAngle.normalized(.infinity) == 0, "non-finite normalizes to 0")

    var angle = 350.0
    for target in [10.0, 350.0, 5.0, 355.0] {
        let next = CompassAngle.unwrapped(from: angle, to: target)
        check(abs(next - angle) <= 180, "each step moves at most 180°")
        angle = next
    }

    check(ReadoutFormat.temperature(21.4) == "21º", "temperature suffix")
    check(ReadoutFormat.temperature(-0.3) == "0º", "negative zero is plain 0")
    check(ReadoutFormat.temperature(-4.6) == "-5º", "negative temperatures round")
    check(ReadoutFormat.temperature(.nan) == "--", "NaN shows placeholder")
    check(ReadoutFormat.windSpeed(5.5) == "6", "wind rounds to whole km/h")

    check(CompassAngle.normalized(-1e-20) < 360, "tiny negative never normalizes to 360")
    check(ReadoutFormat.temperature(1e300) == "--", "huge values do not trap")
    check(ReadoutFormat.windSpeed(.nan) == "--" && ReadoutFormat.windSpeed(-0.4) == "0", "wind edge cases")

    MainActor.assumeIsolated {
        let model = WeatherModel.mock()
        check(model.compassRotation == MockData.windDirection && MockData.windDirection == 250, "mock model starts at mock direction")
        model.setWindDirection(350)
        model.setWindDirection(10)
        check(model.compassRotation == 370 && model.windDirection == 10, "model unwraps across north")
    }

    check(MockData.location == "Vila Real" && MockData.temperature == 21 && MockData.windSpeed == 6, "mock matches screenshot")
    check(MockData.forecast.count == 7, "mock has 7 days")
    check(MockData.forecast[0] == DailyForecast(day: "Tue", high: 22, low: 16, code: 0), "mock Tue 22/16")
    check(MockData.forecast[1] == DailyForecast(day: "Wed", high: 20, low: 13, code: 0), "mock Wed 20/13")
}
