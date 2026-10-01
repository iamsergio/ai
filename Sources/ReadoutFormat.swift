import Foundation

/// Text for the numeric readouts. Values are rounded to whole numbers.
enum ReadoutFormat {
    static func rounded(_ value: Double) -> String {
        guard value.isFinite, let n = Int(exactly: value.rounded()) else { return "--" }
        return String(n)
    }

    /// Temperature with the "º" (masculine ordinal) suffix used by the design, e.g. "21º".
    static func temperature(_ celsius: Double) -> String {
        let text = rounded(celsius)
        return text == "--" ? text : text + "º"
    }

    static func windSpeed(_ kmh: Double) -> String { rounded(kmh) }
}
