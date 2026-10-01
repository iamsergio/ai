import AppKit

/// The single window-size constant, in points. Everything else is relative to it.
let windowSize: CGFloat = 500

final class GadgetWindow: NSWindow {
    // Borderless windows refuse key status by default.
    override var canBecomeKey: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let debug = DebugOptions()
        installMainMenu()

        let window = GadgetWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize, height: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.contentView = DialHostingView(rootView: GadgetView(debug: debug))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)

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
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? png.write(to: URL(fileURLWithPath: path))) != nil
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
