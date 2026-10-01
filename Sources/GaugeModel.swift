import Observation

/// Values shown on the dial. Mock data for now; M6 replaces it with live weather.
@MainActor @Observable
final class GaugeModel {
    var temperature = MockData.temperature
    var windSpeed = MockData.windSpeed
    var locationName = MockData.location
    /// Unbounded chevron rotation in degrees. Always reached through `setWindDirection`, so
    /// animating it takes the shortest path.
    private(set) var compassRotation = MockData.windDirection
    var forecast: [DailyForecast] = MockData.forecast

    var temperatureProgress: Double { GaugeScale.temperature.progress(for: temperature) }
    var windProgress: Double { GaugeScale.wind.progress(for: windSpeed) }

    /// Wind direction in degrees, 0° = north, clockwise.
    var windDirection: Double { CompassAngle.normalized(compassRotation) }

    func setWindDirection(_ degrees: Double) {
        compassRotation = CompassAngle.unwrapped(from: compassRotation, to: degrees)
    }

    /// Debug key: jump to random values inside the gauge ranges to exercise the animation.
    func randomize() {
        temperature = .random(in: GaugeScale.temperature.lowerBound...GaugeScale.temperature.upperBound)
        windSpeed = .random(in: GaugeScale.wind.lowerBound...GaugeScale.wind.upperBound)
        setWindDirection(.random(in: 0..<360))
    }
}
