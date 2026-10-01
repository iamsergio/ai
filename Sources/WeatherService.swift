import Foundation

/// One successful Open-Meteo response, reduced to what the gadget shows.
struct WeatherSnapshot: Equatable {
    let temperature: Double
    let windSpeed: Double
    let windDirection: Double
    let code: Int
    let isDay: Bool
    /// The next 7 days (today is dropped).
    let forecast: [DailyForecast]
}

enum WeatherService {
    enum Failure: Error { case invalidResponse }

    static func url(latitude: Double, longitude: Double) -> URL {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day"),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            .init(name: "forecast_days", value: "8"),
            .init(name: "timezone", value: "auto"),
        ]
        return c.url!
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let wind_speed_10m: Double
            let wind_direction_10m: Double
            let weather_code: Int
            let is_day: Int
        }
        struct Daily: Decodable {
            let time: [String]
            let weather_code: [Int]
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
        }
        let current: Current
        let daily: Daily
    }

    static func decode(_ data: Data) throws -> WeatherSnapshot {
        let r = try JSONDecoder().decode(Response.self, from: data)
        let d = r.daily
        guard d.weather_code.count == d.time.count, d.temperature_2m_max.count == d.time.count,
              d.temperature_2m_min.count == d.time.count else { throw Failure.invalidResponse }
        // Index 0 is today; the gadget shows the following days.
        let forecast = try d.time.indices.dropFirst().map { i in
            guard let name = weekdayName(forDate: d.time[i]) else { throw Failure.invalidResponse }
            return DailyForecast(day: name, high: d.temperature_2m_max[i], low: d.temperature_2m_min[i],
                                 code: d.weather_code[i])
        }
        return WeatherSnapshot(temperature: r.current.temperature_2m, windSpeed: r.current.wind_speed_10m,
                               windDirection: r.current.wind_direction_10m, code: r.current.weather_code,
                               isDay: r.current.is_day != 0, forecast: forecast)
    }

    /// "2026-10-02" → "Fri". The date is already local to the forecast location, so no zone maths.
    static func weekdayName(forDate iso: String) -> String? {
        let parse = DateFormatter()
        parse.locale = Locale(identifier: "en_US_POSIX")
        parse.timeZone = TimeZone(identifier: "UTC")
        parse.dateFormat = "yyyy-MM-dd"
        guard let date = parse.date(from: iso) else { return nil }
        parse.dateFormat = "EEE"
        return parse.string(from: date)
    }

    static func fetch(latitude: Double, longitude: Double, using fetch: DataFetcher) async throws -> WeatherSnapshot {
        try decode(try await fetch(url(latitude: latitude, longitude: longitude)))
    }
}
