import AppKit
import SceneKit

/// The single window-size constant, in points. Everything else is relative to it.
let windowSize: CGFloat = 500

final class GadgetWindow: NSWindow {
    // Borderless windows refuse key status by default.
    override var canBecomeKey: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var gauges = WeatherModel()
    private var refreshTask: Task<Void, Never>?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let debug = DebugOptions()
        installMainMenu()

        if debug.useMockData {
            gauges = .mock()
        } else {
            refreshTask = Task { [gauges] in await gauges.run() }
        }

        let window = GadgetWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize, height: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.contentView = DialHostingView(rootView: GadgetView(model: gauges, debug: debug))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)

        if debug.debugKeys {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [gauges] event in
                guard !event.isARepeat,
                      event.charactersIgnoringModifiers?.lowercased() == "r",
                      event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return event }
                gauges.randomize()
                return nil
            }
        }

        if debug.printWindowID {
            // The window number is the CGWindowID expected by `screencapture -l`.
            print("GADGET_WINDOW_ID=\(window.windowNumber)")
            fflush(stdout)
        }

        if let path = debug.snapshotPath {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let ok = Self.writeSnapshot(of: window, to: path)
                print(ok ? "Wrote \(path)" : "Snapshot failed")
                fflush(stdout)
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// Renders the window content (with alpha) straight to a PNG, independent of the window server.
    private static func writeSnapshot(of window: NSWindow, to path: String) -> Bool {
        guard let view = window.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return false }
        view.cacheDisplay(in: view.bounds, to: rep)
        drawSceneViews(of: view, into: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? png.write(to: URL(fileURLWithPath: path))) != nil
    }

    /// `cacheDisplay` doesn't capture SceneKit's Metal output, so each `SCNView` is drawn from its own
    /// snapshot, clipped to the pager circle. The hard clip approximates the pager's soft vignette.
    private static func drawSceneViews(of view: NSView, into rep: NSBitmapImageRep) {
        func sceneViews(in v: NSView) -> [SCNView] {
            v.subviews.flatMap { ($0 as? SCNView).map { [$0] } ?? sceneViews(in: $0) }
        }
        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = ctx
        let b = view.bounds
        let d = min(b.width, b.height)
        let r = d * PagerLayout.diameter / 2
        // The bitmap context is unflipped: y grows upwards, so the pager centre lies below midY.
        let flip = { (rect: NSRect) in view.isFlipped ? NSRect(x: rect.minX, y: b.height - rect.maxY,
                                                               width: rect.width, height: rect.height) : rect }
        let centre = flip(NSRect(x: b.midX, y: b.midY + d * PagerLayout.centreOffset, width: 0, height: 0)).origin
        NSBezierPath(ovalIn: NSRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r)).addClip()
        for scn in sceneViews(in: view) where !scn.isHiddenOrHasHiddenAncestor {
            scn.snapshot().draw(in: flip(scn.convert(scn.bounds, to: view)))
        }
    }

    /// Minimal menu so that ⌘Q works.
    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
}

@main
enum MyApp {
    @MainActor static var delegate = AppDelegate()

    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.run()
    }
}
