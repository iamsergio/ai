import Foundation

/// Debug switches read from environment variables (see CLAUDE.md "Visual verification").
struct DebugOptions: Equatable {
    var printWindowID = false
    var referenceImagePath: String?
    var useMockData = false
    /// Render the content view to this PNG shortly after launch, then quit. Needs no screen access.
    var snapshotPath: String?
    /// Start on the forecast page (`GADGET_PAGE=2`).
    var startOnForecast = false

    /// Debug keys (R randomizes the gauges) are active when either debug switch is set.
    var debugKeys: Bool { printWindowID || useMockData }

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        printWindowID = environment["GADGET_DEBUG"] == "1"
        useMockData = environment["GADGET_MOCK"] == "1"
        startOnForecast = environment["GADGET_PAGE"] == "2"
        if let path = environment["GADGET_SNAPSHOT"], !path.isEmpty {
            snapshotPath = path
        }
        if let path = environment["GADGET_REF"], !path.isEmpty {
            referenceImagePath = path
        }
    }
}
