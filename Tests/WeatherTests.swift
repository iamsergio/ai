import Foundation

private let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
private let iconDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("img/weather-icons")

private func fixture(_ name: String) -> Data {
    (try? Data(contentsOf: fixtures.appendingPathComponent(name))) ?? Data()
}

private struct Offline: Error {}

func runWeatherTests() {
    // Open-Meteo: today is dropped, 7 days remain.
    if let s = try? WeatherService.decode(fixture("open-meteo.json")) {
        check(s.temperature == 16.9 && s.windSpeed == 8.4 && s.windDirection == 65, "current values decoded")
        check(s.code == 3 && s.isDay, "code and isDay decoded")
        check(s.forecast.count == 7, "7 forecast days")
        // Fixture dates start 2026-10-01 (Thu); today is dropped, so the first card is Fri 2026-10-02.
        check(s.forecast.first == DailyForecast(day: "Fri", high: 23.9, low: 12.2, code: 3), "first forecast day is tomorrow")
        check(s.forecast.last?.day == "Thu" && s.forecast.last?.code == 3, "last forecast day")
        check(s.forecast.map(\.code) == [3, 3, 3, 95, 80, 45, 3], "forecast codes")
    } else {
        check(false, "open-meteo fixture decodes")
    }
    check((try? WeatherService.decode(Data("{}".utf8))) == nil, "garbage rejected")
    let truncated = #"{"current":{"temperature_2m":1,"wind_speed_10m":1,"wind_direction_10m":1,"weather_code":0,"is_day":1},"daily":{"time":["2026-10-01"],"weather_code":[],"temperature_2m_max":[1],"temperature_2m_min":[1]}}"#
    check((try? WeatherService.decode(Data(truncated.utf8))) == nil, "mismatched daily arrays rejected")
    let q = WeatherService.url(latitude: 41.3, longitude: -7.7).absoluteString
    check(q.contains("forecast_days=8") && q.contains("timezone=auto") && q.contains("wind_direction_10m"), "request URL")

    // IP geolocation.
    let vila = GeoLocation(latitude: 41.3006, longitude: -7.7441, city: "Vila Real")
    check((try? LocationService.decodeIPAPI(fixture("ipapi.json"))) == vila, "ipapi.co decodes")
    check((try? LocationService.decodeIPWhoIs(fixture("ipwhois.json"))) == vila, "ipwho.is decodes")
    check((try? LocationService.decodeIPWhoIs(fixture("ipwhois-failure.json"))) == nil, "ipwho.is failure rejected")
    check((try? LocationService.decodeIPAPI(Data(#"{"error":true,"reason":"RateLimited"}"#.utf8))) == nil, "ipapi error rejected")
    check((try? LocationService.decodeIPAPI(Data(#"{"latitude":95,"longitude":0}"#.utf8))) == nil, "out-of-range latitude rejected")

    // Fallback provider: primary offline, secondary answers.
    let primary = LocationService.providers[0].url
    let fallback: DataFetcher = { url in
        if url == primary { throw Offline() }
        return fixture("ipwhois.json")
    }
    let located = blocking { try? await LocationService.locate(using: fallback) }
    check(located == vila, "falls back to second provider")
    let none = blocking { try? await LocationService.locate(using: { _ in throw Offline() }) }
    check(none == nil, "all providers failing throws")

    // Icon mapping.
    check(WeatherCode.iconName(code: 0, isDay: true) == "weather-clear-symbolic.svg", "clear")
    check(WeatherCode.iconName(code: 1, isDay: false) == "weather-few-clouds-night-symbolic.svg", "few clouds night")
    check(WeatherCode.iconName(code: 1, isDay: true) == "weather-few-clouds-symbolic.svg", "few clouds day")
    check(WeatherCode.iconName(code: 3, isDay: false) == "weather-many-clouds-symbolic.svg", "overcast has no night variant")
    check(WeatherCode.iconName(code: 63, isDay: true) == "weather-showers-day-symbolic.svg", "rain day")
    check(WeatherCode.iconName(code: 95, isDay: false) == "weather-storm-night-symbolic.svg", "storm night")
    check(WeatherCode.iconName(code: 99, isDay: true) == "weather-hail-symbolic.svg", "hail")
    check(WeatherCode.iconName(code: 42, isDay: true) == WeatherCode.unknownIcon, "unknown code")
    check(WeatherCode.iconName(code: -1, isDay: true) == WeatherCode.unknownIcon, "negative code")
    let files = Set((try? FileManager.default.contentsOfDirectory(atPath: iconDir.path)) ?? [])
    check(!files.isEmpty, "icon directory found")
    for code in -1...120 {
        for isDay in [true, false] {
            let name = WeatherCode.iconName(code: code, isDay: isDay)
            check(files.contains(name), "icon exists for code \(code) isDay \(isDay): \(name)")
        }
    }

    // Model: first success fills data, a later failure keeps it.
    let result = blocking { await modelScenario() }
    check(result.initialEmpty, "model starts empty")
    check(result.firstOK && result.name == "Vila Real" && result.temp == 16.9 && result.days == 7, "refresh fills model")
    check(!result.secondOK && result.keptTemp == 16.9 && result.keptDays == 7, "failed refresh keeps last good data")
    check(result.direction == 65, "wind direction applied")
}

private struct ModelResult {
    var initialEmpty = false, firstOK = false, secondOK = true
    var name: String?, temp: Double?, days = 0, keptTemp: Double?, keptDays = 0, direction = 0.0
}

private final class Switch: @unchecked Sendable {
    private let lock = NSLock()
    private var _offline = false
    var offline: Bool {
        get { lock.withLock { _offline } }
        set { lock.withLock { _offline = newValue } }
    }
}

@MainActor
private func modelScenario() async -> ModelResult {
    let sw = Switch()
    let model = WeatherModel(fetcher: { url in
        if sw.offline { throw Offline() }
        return url.host == "api.open-meteo.com" ? fixture("open-meteo.json") : fixture("ipapi.json")
    })
    var r = ModelResult()
    r.initialEmpty = model.temperature == nil && model.locationName == nil && model.temperatureProgress == 0
    r.firstOK = await model.refresh()
    r.name = model.locationName
    r.temp = model.temperature
    r.days = model.forecast.count
    r.direction = model.windDirection
    sw.offline = true
    r.secondOK = await model.refresh()
    r.keptTemp = model.temperature
    r.keptDays = model.forecast.count
    return r
}

/// Runs async work to completion from the synchronous test entry points.
private func blocking<T: Sendable>(_ work: @escaping @Sendable () async -> T) -> T {
    let box = ResultBox<T>()
    let done = DispatchSemaphore(value: 0)
    Task {
        box.value = await work()
        done.signal()
    }
    while done.wait(timeout: .now() + 0.01) == .timedOut {
        RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
    }
    return box.value!
}

private final class ResultBox<T>: @unchecked Sendable { var value: T? }
