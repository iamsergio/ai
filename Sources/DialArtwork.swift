import SwiftUI

/// Static dial artwork (M3): metallic rim, black bezel, teal face and the wordmark.
/// Sized from the dial diameter `d`; radii are fractions of R = d / 2 (PLAN.md "Geometry reference").
struct DialArtwork: View {
    let d: CGFloat

    private var r: CGFloat { d / 2 }

    var body: some View {
        ZStack {
            rim
            bezel
            face
            wordmark
        }
        .frame(width: d, height: d)
    }

    // MARK: Rim

    private var rim: some View {
        let metal = Gradient(stops: [
            .init(color: Color(white: 0.86), location: 0.00),
            .init(color: Color(white: 0.45), location: 0.10),
            .init(color: Color(white: 0.78), location: 0.22),
            .init(color: Color(white: 0.40), location: 0.36),
            .init(color: Color(white: 0.82), location: 0.50),
            .init(color: Color(white: 0.42), location: 0.64),
            .init(color: Color(white: 0.80), location: 0.78),
            .init(color: Color(white: 0.48), location: 0.90),
            .init(color: Color(white: 0.86), location: 1.00),
        ])
        return ZStack {
            Circle().fill(AngularGradient(gradient: metal, center: .center, angle: .degrees(-60)))
            // Top light: bright at the top, fading to nothing at the bottom.
            Circle().fill(LinearGradient(colors: [.white.opacity(0.55), .clear, .black.opacity(0.25)],
                                         startPoint: .top, endPoint: .bottom))
            // Thin dark outer edge.
            Circle().strokeBorder(Color.black.opacity(0.65), lineWidth: max(1, d * 0.004))
        }
    }

    // MARK: Bezel

    private var bezel: some View {
        let size = d * DialGeometry.bezelOuterFraction
        return ZStack {
            Circle().fill(Color(white: 0.07))
            Circle().fill(LinearGradient(colors: [.white.opacity(0.16), .clear, .clear],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            // Hairline where the bezel meets the rim.
            Circle().strokeBorder(Color.black, lineWidth: max(1, d * 0.003))
        }
        .frame(width: size, height: size)
    }

    // MARK: Face

    private var face: some View {
        let size = d * DialGeometry.faceRadiusFraction
        return ZStack {
            Circle().fill(RadialGradient(
                colors: [Color(red: 0.03, green: 0.44, blue: 0.50),
                         Color(red: 0.02, green: 0.28, blue: 0.32),
                         Color(red: 0.0, green: 0.05, blue: 0.07)],
                center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: size * 0.78))
            // Cyan glow on the lower inner edge.
            Circle()
                .strokeBorder(Color(red: 0.1, green: 0.8, blue: 0.9).opacity(0.6), lineWidth: size * 0.05)
                .blur(radius: size * 0.04)
                .mask(LinearGradient(colors: [.clear, .clear, .black], startPoint: .top, endPoint: .bottom))
            // Inner shadow where the face meets the bezel.
            Circle()
                .strokeBorder(Color.black.opacity(0.75), lineWidth: size * 0.03)
                .blur(radius: size * 0.035)
                .mask(LinearGradient(colors: [.black, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: Wordmark

    private var wordmark: some View {
        Text("best")
            .tracking(-d * 0.004)
            .font(.system(size: d * DialGeometry.wordmarkFontFraction, weight: .bold))
            .foregroundStyle(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.62)],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.6), radius: d * 0.003, y: d * 0.002)
            .offset(y: -r * DialGeometry.wordmarkOffsetFraction)
    }
}
