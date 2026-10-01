import AppKit
import SwiftUI

/// Hosts `GadgetView` and implements the window-level mouse behaviour:
/// the ring/bezel drags the window, the face is left to the content. Click-through in the transparent
/// corners is done by the window server from pixel alpha (the window is non-opaque), so nothing may be
/// painted outside the dial circle. `hitTest` returning nil only stops dispatch inside our own window.
final class DialHostingView: NSHostingView<GadgetView> {
    private var geometry: DialGeometry { DialGeometry(diameter: min(bounds.width, bounds.height)) }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        return menu
    }()

    override func hitTest(_ point: NSPoint) -> NSView? {
        switch geometry.zone(at: convert(point, from: superview)) {
        case .outside: return nil
        case .ring: return self
        case .face: return super.hitTest(point)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let isRing = geometry.zone(at: convert(event.locationInWindow, from: nil)) == .ring
        if isRing && !event.modifierFlags.contains(.control) {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    // Handles both right-click and Control-click.
    override func menu(for event: NSEvent) -> NSMenu? { contextMenu }
}
