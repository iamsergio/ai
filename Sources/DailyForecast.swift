import Foundation

struct DailyForecast: Equatable {
    let day: String
    let high: Double
    let low: Double
    /// WMO weather code, see `WeatherCode`.
    var code: Int = 0
}
