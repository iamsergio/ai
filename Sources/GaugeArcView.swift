import SwiftUI

/// A gauge: dark full-length track, then the coloured value arc with round caps and a soft glow.
struct GaugeArcView: View {
    let d: CGFloat
    let spec: ArcSpec
    let progress: Double
    /// Colour stops from the arc start (bottom) to its end (top).
    let colors: [Color]
    let glow: Double

    private var radius: CGFloat { d / 2 * ArcSpec.radiusFraction }
    private var lineWidth: CGFloat { d * ArcSpec.lineWidthFraction }

    /// The gradient is fixed to the full arc, so a high value reveals the far colours.
    private var gradient: AngularGradient {
        AngularGradient(colors: spec.reversesColors ? colors.reversed() : colors, center: .center,
                        startAngle: .degrees(spec.gradientRange.lowerBound),
                        endAngle: .degrees(spec.gradientRange.upperBound))
    }

    var body: some View {
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        ZStack {
            ArcGauge(spec: spec, radius: radius, progress: 1)
                .stroke(Color.black.opacity(0.28), style: style)
            ArcGauge(spec: spec, radius: radius, progress: progress)
                .stroke(gradient, style: style)
                .blur(radius: lineWidth * 0.9)
                .opacity(glow)
            ArcGauge(spec: spec, radius: radius, progress: progress)
                .stroke(gradient, style: style)
        }
        .frame(width: d, height: d)
        .animation(.easeOut(duration: 0.8), value: progress)
    }
}
