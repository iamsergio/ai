import Observation
import Foundation

/// Values shown on the dial. `nil` means "no data yet" and renders as "--".
@MainActor @Observable
final class WeatherModel {
    static let refreshInterval: Duration = .seconds(600)
    static let retryInterval: Duration = .seconds(60)

    var temperature: Double?
    var windSpeed: Double?
    var weatherCode: Int?
    var isDay = true
    var locationName: String?
    /// Unbounded chevron rotation in degrees. Always reached through `setWindDirection`, so
    /// animating it takes the shortest path.
    private(set) var compassRotation = 0.0
    var forecast: [DailyForecast] = []

    @ObservationIgnored private let fetcher: DataFetcher
    @ObservationIgnored private var location: GeoLocation?

    init(fetcher: @escaping DataFetcher = Fetching.live) {
        self.fetcher = fetcher
    }

    /// A model preloaded with the fixed data from the reference screenshots (`GADGET_MOCK=1`).
    static func mock() -> WeatherModel {
        let model = WeatherModel()
        model.temperature = MockData.temperature
        model.windSpeed = MockData.windSpeed
        model.locationName = MockData.location
        model.weatherCode = 3
        model.compassRotation = MockData.windDirection
        model.forecast = MockData.forecast
        return model
    }

    var temperatureProgress: Double { temperature.map(GaugeScale.temperature.progress(for:)) ?? 0 }
    var windProgress: Double { windSpeed.map(GaugeScale.wind.progress(for:)) ?? 0 }

    /// Wind direction in degrees, 0° = north, clockwise.
    var windDirection: Double { CompassAngle.normalized(compassRotation) }

    /// Icon file for the current conditions, relative to `img/`.
    var currentIconResource: String {
        WeatherCode.iconResource(code: weatherCode ?? -1, isDay: isDay)
    }

    func setWindDirection(_ degrees: Double) {
        compassRotation = CompassAngle.unwrapped(from: compassRotation, to: degrees)
    }

    /// Fetches location (once) and weather. On failure the last good data stays. Returns success.
    func refresh() async -> Bool {
        do {
            let place: GeoLocation
            if let known = location {
                place = known
            } else {
                place = try await LocationService.locate(using: fetcher)
                location = place
            }
            let snapshot = try await WeatherService.fetch(latitude: place.latitude, longitude: place.longitude,
                                                          using: fetcher)
            locationName = place.city
            apply(snapshot)
            return true
        } catch {
            return false
        }
    }

    private func apply(_ s: WeatherSnapshot) {
        temperature = s.temperature
        windSpeed = s.windSpeed
        weatherCode = s.code
        isDay = s.isDay
        setWindDirection(s.windDirection)
        forecast = s.forecast
    }

    /// Refreshes now, then every 10 minutes (every minute after a failure) until cancelled.
    func run() async {
        while !Task.isCancelled {
            let ok = await refresh()
            try? await Task.sleep(for: ok ? Self.refreshInterval : Self.retryInterval)
        }
    }

    /// Debug key: jump to random values inside the gauge ranges to exercise the animation.
    func randomize() {
        temperature = .random(in: GaugeScale.temperature.lowerBound...GaugeScale.temperature.upperBound)
        windSpeed = .random(in: GaugeScale.wind.lowerBound...GaugeScale.wind.upperBound)
        setWindDirection(.random(in: 0..<360))
    }
}
