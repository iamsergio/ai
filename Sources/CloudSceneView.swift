import SceneKit
import SwiftUI

/// Hosts the 3D cloud in a transparent `SCNView`. Rendering runs only while `active`.
struct CloudSceneView: NSViewRepresentable {
    var active: Bool

    /// Never takes the mouse, so the pager's drag gesture keeps working over the cloud.
    final class PassThroughView: SCNView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }

    func makeNSView(context: Context) -> SCNView {
        let view = PassThroughView(frame: .zero)
        view.scene = CloudScene.make()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 30
        view.isPlaying = active
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        view.isPlaying = active
        view.scene?.isPaused = !active
    }
}
