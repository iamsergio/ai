import CoreGraphics

func runDialGeometryTests() {
    let g = DialGeometry(diameter: 500)
    check(g.zone(at: CGPoint(x: 250, y: 250)) == .face, "centre is face")
    check(g.zone(at: CGPoint(x: 250, y: 250 - 0.5 * 250)) == .face, "0.5R is face")
    check(g.zone(at: CGPoint(x: 250 + 0.85 * 250, y: 250)) == .ring, "0.85R is ring")
    check(g.zone(at: CGPoint(x: 250, y: 250 + 0.99 * 250)) == .ring, "0.99R is ring")
    check(g.zone(at: CGPoint(x: 1, y: 1)) == .outside, "corner is outside")
    check(g.zone(at: CGPoint(x: 250, y: -1)) == .outside, "above the dial is outside")
    check(g.zone(at: CGPoint(x: 250 + 0.72 * 250, y: 250)) == .face, "just inside face edge")
    check(g.zone(at: CGPoint(x: 250 + 0.74 * 250, y: 250)) == .ring, "just outside face edge")

    // Reference overlay: at D = 840 the scale is exactly 1, so the image maps 1:1 with its ring centre at D/2.
    let l = ReferenceOverlayLayout(diameter: 840)
    check(l.side == 900, "scale 1 keeps image size")
    check(l.origin == CGPoint(x: 420 - 432, y: 420 - 485), "ring centre lands on dial centre")
    let half = ReferenceOverlayLayout(diameter: 420)
    check(half.side == 450, "scale 0.5 halves image")

    let env = DebugOptions(environment: ["GADGET_DEBUG": "1", "GADGET_REF": "/x.png"])
    check(env.printWindowID && env.referenceImagePath == "/x.png" && !env.useMockData, "debug env parsed")
    check(DebugOptions(environment: [:]) == DebugOptions(environment: ["GADGET_REF": ""]), "empty ref ignored")
}
