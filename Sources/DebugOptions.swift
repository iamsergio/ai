import Foundation

/// Debug switches read from environment variables (see CLAUDE.md "Visual verification").
struct DebugOptions: Equatable {
    var printWindowID = false
    var referenceImagePath: String?
    var useMockData = false

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        printWindowID = environment["GADGET_DEBUG"] == "1"
        useMockData = environment["GADGET_MOCK"] == "1"
        if let path = environment["GADGET_REF"], !path.isEmpty {
            referenceImagePath = path
        }
    }
}
