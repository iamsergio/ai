import SwiftUI

/// Text readouts on the teal face: wind speed and compass on top, location and temperature below.
struct ReadoutsView: View {
    let d: CGFloat
    let model: WeatherModel

    // Offsets from the dial centre and font sizes, as fractions of D (PLAN.md "Geometry reference").
    private let windTextOffset: CGFloat = 0.29
    private let compassOffset: CGFloat = 0.225
    private let locationOffset: CGFloat = 0.22
    private let temperatureOffset: CGFloat = 0.287

    var body: some View {
        ZStack {
            HStack(alignment: .firstTextBaseline, spacing: d * 0.006) {
                Text(ReadoutFormat.windSpeed(model.windSpeed ?? .nan))
                    .font(.system(size: d * 0.024, weight: .bold))
                Text("km/h")
                    .font(.system(size: d * 0.018, weight: .bold))
            }
            .foregroundStyle(Color(white: 0.85))
            .offset(y: -d * windTextOffset)

            WindCompass(d: d, rotation: model.compassRotation)
                .offset(y: -d * compassOffset)

            Text(model.locationName ?? "--")
                .font(.system(size: d * 0.033))
                .foregroundStyle(Color(white: 0.78))
                .offset(y: d * locationOffset)

            Text(ReadoutFormat.temperature(model.temperature ?? .nan))
                .font(.system(size: d * 0.085, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: d * temperatureOffset)
        }
        .frame(width: d, height: d)
    }
}
