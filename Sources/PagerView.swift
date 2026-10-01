import SwiftUI

/// Two stacked pages in a circular area: page 1 (current conditions) and page 2 (7-day strip).
/// A single drag gesture locks to an axis: vertical changes page, horizontal scrolls the strip (page 2 only).
struct PagerView: View {
    let d: CGFloat
    let model: WeatherModel
    var startPage = 0

    @State private var page = 0
    /// Vertical content offset in points: 0 = page 1, pageHeight = page 2.
    @State private var pageOffset: CGFloat = 0
    /// Horizontal strip offset in points, 0 = first card centred.
    @State private var stripOffset: CGFloat = 0
    @State private var lock = AxisLock()
    @State private var dragging = false
    @State private var dragStartPage = 0
    @State private var dragStartStrip: CGFloat = 0

    private var size: CGFloat { d * PagerLayout.diameter }
    private var spacing: CGFloat { d * PagerLayout.cardSpacing }
    private var maxStrip: CGFloat { PagerMath.maxStripOffset(cardCount: model.forecast.count, spacing: spacing) }
    private let spring = Animation.spring(response: 0.45, dampingFraction: 0.82)

    var body: some View {
        ZStack {
            currentPage
                .offset(y: -pageOffset)
            forecastStrip
                .offset(y: size - pageOffset)
        }
        .frame(width: size, height: size)
        .mask(vignette)
        .contentShape(Circle())
        .gesture(drag)
        .onAppear {
            page = startPage
            pageOffset = CGFloat(startPage) * size
        }
        .offset(y: d * PagerLayout.centreOffset)
    }

    /// Black up to `vignetteStart`, fading to clear at the edge.
    private var vignette: some View {
        RadialGradient(stops: [.init(color: .black, location: 0),
                               .init(color: .black, location: PagerLayout.vignetteStart),
                               .init(color: .clear, location: 1)],
                       center: .center, startRadius: 0, endRadius: size / 2)
    }

    private var currentPage: some View {
        Group {
            if let image = nsImage(model.currentIconResource) {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: d * 0.22, height: d * 0.22)
            }
        }
        .frame(width: size, height: size)
    }

    private var forecastStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(model.forecast.prefix(7).enumerated()), id: \.offset) { _, day in
                DayCard(d: d, day: day)
            }
        }
        // First card centred at offset 0.
        .frame(width: size, alignment: .leading)
        .offset(x: size / 2 - spacing / 2 - stripOffset)
        .frame(width: size, height: size, alignment: .leading)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging {
                    dragging = true
                    dragStartPage = page
                    dragStartStrip = stripOffset
                }
                switch lock.update(translation: value.translation) {
                case .vertical:
                    let raw = CGFloat(dragStartPage) * size - value.translation.height
                    pageOffset = PagerMath.resisted(raw, maxOffset: size, limit: size * 0.3)
                case .horizontal where page == 1:
                    let raw = dragStartStrip - value.translation.width
                    stripOffset = PagerMath.resisted(raw, maxOffset: maxStrip, limit: size * 0.3)
                default:
                    break
                }
            }
            .onEnded { value in
                defer { lock.reset(); dragging = false }
                switch lock.axis {
                case .vertical:
                    page = PagerMath.snappedPage(from: dragStartPage, translation: value.translation.height,
                                                 predictedEnd: value.predictedEndTranslation.height,
                                                 pageHeight: size, pageCount: 2)
                    withAnimation(spring) { pageOffset = CGFloat(page) * size }
                case .horizontal where page == 1:
                    let target = PagerMath.settledOffset(from: dragStartStrip,
                                                         predictedEnd: value.predictedEndTranslation.width,
                                                         maxOffset: maxStrip)
                    withAnimation(spring) { stripOffset = target }
                default:
                    withAnimation(spring) { pageOffset = CGFloat(page) * size }
                }
            }
    }
}
