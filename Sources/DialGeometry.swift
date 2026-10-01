import CoreGraphics

enum DialZone: Equatable {
    case outside, ring, face
}

/// Pure geometry of the dial, as fractions of its radius `R = D / 2`. See PLAN.md "Geometry reference".
struct DialGeometry {
    /// Teal face radius as a fraction of R. Everything between this and R is rim and bezel.
    static let faceRadiusFraction: CGFloat = 0.73

    let diameter: CGFloat

    var radius: CGFloat { diameter / 2 }

    /// Classifies a point given in view coordinates (origin at a corner, dial centred in the square).
    func zone(at point: CGPoint) -> DialZone {
        let dx = point.x - radius
        let dy = point.y - radius
        let distance = (dx * dx + dy * dy).squareRoot()
        if distance > radius { return .outside }
        return distance > radius * Self.faceRadiusFraction ? .ring : .face
    }
}

/// Placement of the reference screenshot (`GADGET_REF`) so that its ring matches ours.
struct ReferenceOverlayLayout: Equatable {
    // Measured on the 900 px reference screenshots (PLAN.md).
    static let imageSide: CGFloat = 900
    static let ringRadius: CGFloat = 420
    static let ringCentre = CGPoint(x: 432, y: 485)

    let side: CGFloat
    /// Top-left of the image relative to the top-left of the dial's bounding square.
    let origin: CGPoint

    init(diameter: CGFloat) {
        let scale = (diameter / 2) / Self.ringRadius
        side = Self.imageSide * scale
        origin = CGPoint(x: diameter / 2 - Self.ringCentre.x * scale,
                         y: diameter / 2 - Self.ringCentre.y * scale)
    }
}
