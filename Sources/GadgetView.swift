import SwiftUI

/// Root view of the gadget. Everything is sized from the dial diameter `D`.
struct GadgetView: View {
    private let referenceImage: NSImage?
    let model: GaugeModel

    init(model: GaugeModel, debug: DebugOptions = DebugOptions()) {
        self.model = model
        if let path = debug.referenceImagePath {
            referenceImage = NSImage(contentsOfFile: path)
            if referenceImage == nil {
                FileHandle.standardError.write(Data("GADGET_REF: cannot load \(path)\n".utf8))
            }
        } else {
            referenceImage = nil
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let d = min(proxy.size.width, proxy.size.height)
            ZStack {
                DialArtwork(d: d)
                GaugeArcView(d: d, spec: .left, progress: model.temperatureProgress,
                             colors: [.white, Color(red: 0.2, green: 1.0, blue: 0.55),
                                      Color(red: 0.15, green: 0.5, blue: 1.0), Color(red: 0.9, green: 0.2, blue: 0.8)],
                             glow: 0.7)
                GaugeArcView(d: d, spec: .right, progress: model.windProgress,
                             colors: [.white, Color(white: 0.55), Color(white: 0.2)],
                             glow: 0.35)
                referenceOverlay(diameter: d)
            }
            .frame(width: d, height: d)
        }
    }

    @ViewBuilder
    private func referenceOverlay(diameter d: CGFloat) -> some View {
        if let image = referenceImage {
            let layout = ReferenceOverlayLayout(diameter: d)
            Image(nsImage: image)
                .resizable()
                .frame(width: layout.side, height: layout.side)
                .position(x: layout.origin.x + layout.side / 2, y: layout.origin.y + layout.side / 2)
                .frame(width: d, height: d)
                .clipShape(Circle())
                .opacity(0.5)
                .allowsHitTesting(false)
        }
    }
}
