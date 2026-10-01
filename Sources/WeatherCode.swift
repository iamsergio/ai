/// Maps WMO weather codes (as returned by Open-Meteo) to files in `img/weather-icons/`.
enum WeatherCode {
    /// Which suffixed variants exist for an icon.
    private enum Variants {
        case none       // one file for day and night
        case nightOnly  // plain file for day, `-night` for night
        case dayNight   // `-day` and `-night`
    }

    static let unknownIcon = "weather-none-available-symbolic.svg"

    /// Icon file name (relative to `img/weather-icons/`). The forecast always passes `isDay: true`.
    static func iconName(code: Int, isDay: Bool) -> String {
        guard let (base, variants) = entry(for: code) else { return unknownIcon }
        switch variants {
        case .none: return "weather-\(base)-symbolic.svg"
        case .nightOnly: return "weather-\(base)\(isDay ? "" : "-night")-symbolic.svg"
        case .dayNight: return "weather-\(base)-\(isDay ? "day" : "night")-symbolic.svg"
        }
    }

    /// Path usable with `nsImage(_:)`.
    static func iconResource(code: Int, isDay: Bool) -> String {
        "weather-icons/" + iconName(code: code, isDay: isDay)
    }

    private static func entry(for code: Int) -> (String, Variants)? {
        switch code {
        case 0: ("clear", .none)
        case 1: ("few-clouds", .nightOnly)
        case 2: ("clouds", .nightOnly)
        case 3: ("many-clouds", .none)
        case 45, 48: ("fog", .none)
        case 51...55: ("showers-scattered", .dayNight)
        case 56, 57: ("freezing-scattered-rain", .dayNight)
        case 61, 63, 65: ("showers", .dayNight)
        case 66, 67: ("freezing-rain", .dayNight)
        case 71, 73, 75: ("snow", .dayNight)
        case 77: ("snow-scattered", .dayNight)
        case 80: ("showers-scattered", .dayNight)
        case 81, 82: ("showers", .dayNight)
        case 85: ("snow-scattered", .dayNight)
        case 86: ("snow", .dayNight)
        case 95: ("storm", .dayNight)
        case 96, 99: ("hail", .none)
        default: nil
        }
    }
}
