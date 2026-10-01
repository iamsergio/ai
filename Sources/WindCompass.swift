import SwiftUI

/// Small compass: the rose with the chevron on top, rotated to the wind direction.
/// `rotation` is the unbounded angle from `GaugeModel.compassRotation`, so animation takes the short way.
struct WindCompass: View {
    /// Compass diameter as a fraction of the dial diameter D.
    static let sizeFraction: CGFloat = 0.095
    /// Chevron width as a fraction of the compass diameter.
    static let chevronWidthFraction: CGFloat = 0.24
    /// The circle in `wind_rose.png` is centred at (124, 141) of 256 px, not at the image centre.
    /// The chevron pivots around the circle centre, as fractions of the compass size.
    static let circleCentreShift = CGSize(width: -4.0 / 256, height: 13.0 / 256)

    let d: CGFloat
    let rotation: Double

    private static let tint = Color(white: 0.85)
    private static let rose = templateImage("wind_rose.png")
    private static let chevron = templateImage("wind_chevron.png")

    private static func templateImage(_ name: String) -> NSImage? {
        let image = nsImage(name)
        image?.isTemplate = true
        return image
    }

    var body: some View {
        let size = d * Self.sizeFraction
        ZStack {
            layer(Self.rose).frame(width: size, height: size)
            layer(Self.chevron)
                .frame(width: size * Self.chevronWidthFraction)
                .rotationEffect(.degrees(rotation))
                .offset(x: size * Self.circleCentreShift.width, y: size * Self.circleCentreShift.height)
                .animation(.easeOut(duration: 0.8), value: rotation)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func layer(_ image: NSImage?) -> some View {
        if let image {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Self.tint)
        }
    }
}
