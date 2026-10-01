import SwiftUI

/// Arc shape that draws the first `progress` (0...1) of `spec`, centred in its rect with radius `radius`.
/// `progress` is animatable, so value changes interpolate.
struct ArcGauge: Shape {
    var spec: ArcSpec
    var radius: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0 else { return path }
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        // SwiftUI's y axis points down, so `clockwise: true` draws counter-clockwise on screen.
        path.addArc(center: centre, radius: radius,
                    startAngle: .degrees(spec.start), endAngle: .degrees(spec.angle(at: progress)),
                    clockwise: spec.sweep < 0)
        return path
    }
}

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
    /// `AngularGradient` runs clockwise, so a counter-clockwise arc has its colours reversed.
    private var gradient: AngularGradient {
        let clockwise = spec.sweep >= 0
        return AngularGradient(colors: clockwise ? colors : colors.reversed(), center: .center,
                               startAngle: .degrees(min(spec.start, spec.end)),
                               endAngle: .degrees(max(spec.start, spec.end)))
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
