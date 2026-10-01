import Observation

/// Values shown on the gauges. Mock data for now; M6 replaces it with live weather.
@MainActor @Observable
final class GaugeModel {
    var temperature: Double = 21
    var windSpeed: Double = 6

    var temperatureProgress: Double { GaugeScale.temperature.progress(for: temperature) }
    var windProgress: Double { GaugeScale.wind.progress(for: windSpeed) }

    /// Debug key: jump to random values inside the gauge ranges to exercise the animation.
    func randomize() {
        temperature = .random(in: GaugeScale.temperature.lowerBound...GaugeScale.temperature.upperBound)
        windSpeed = .random(in: GaugeScale.wind.lowerBound...GaugeScale.wind.upperBound)
    }
}
