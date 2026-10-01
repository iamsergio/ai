import SwiftUI

/// One forecast day: icon, weekday and "high / low".
struct DayCard: View {
    let d: CGFloat
    let day: DailyForecast

    // Sizes and offsets from the card centre as fractions of D (measured on forecast-page.png).
    private let iconSize: CGFloat = 0.1
    private let iconOffset: CGFloat = -0.05
    private let dayOffset: CGFloat = 0.031
    private let rangeOffset: CGFloat = 0.079

    var body: some View {
        ZStack {
            icon
                .frame(width: d * iconSize, height: d * iconSize)
                .offset(y: d * iconOffset)
            Text(day.day)
                .font(.system(size: d * 0.026, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: d * dayOffset)
            Text(ReadoutFormat.dayRange(high: day.high, low: day.low))
                .font(.system(size: d * 0.019))
                .foregroundStyle(Color(white: 0.8))
                .offset(y: d * rangeOffset)
        }
        .frame(width: d * PagerLayout.cardSpacing, height: d * 0.3)
    }

    @ViewBuilder
    private var icon: some View {
        if let image = nsImage(WeatherCode.iconResource(code: day.code, isDay: true)) {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
        }
    }
}
