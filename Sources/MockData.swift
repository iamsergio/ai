/// Fixed data matching the reference screenshots (`GADGET_MOCK=1`).
/// Only Tue and Wed are visible in `forecast-page.png`; the remaining days are placeholders.
enum MockData {
    static let location = "Vila Real"
    static let temperature = 21.0
    static let windSpeed = 6.0
    static let windDirection = 250.0
    static let forecast: [DailyForecast] = [
        .init(day: "Tue", high: 22, low: 16),
        .init(day: "Wed", high: 20, low: 13),
        .init(day: "Thu", high: 19, low: 12),
        .init(day: "Fri", high: 21, low: 14),
        .init(day: "Sat", high: 23, low: 15),
        .init(day: "Sun", high: 24, low: 16),
        .init(day: "Mon", high: 22, low: 15),
    ]
}
