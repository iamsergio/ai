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

    var arc = ArcGauge(spec: .left, radius: 10, progress: 0.25)
    check(arc.animatableData == 0.25, "progress is animatable data")
    arc.animatableData = 0.75
    check(arc.progress == 0.75, "animatable data sets progress")

    check(!DebugOptions(environment: [:]).debugKeys, "debug keys off by default")
    check(DebugOptions(environment: ["GADGET_DEBUG": "1"]).debugKeys, "GADGET_DEBUG enables debug keys")
    check(DebugOptions(environment: ["GADGET_MOCK": "1"]).debugKeys, "GADGET_MOCK enables debug keys")
}
