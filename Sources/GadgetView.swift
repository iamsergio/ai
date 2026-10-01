import SwiftUI

/// Root view of the gadget. Everything is sized from the dial diameter `D`.
struct GadgetView: View {
    private let referenceImage: NSImage?

    init(debug: DebugOptions = DebugOptions()) {
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
