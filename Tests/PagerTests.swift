import CoreGraphics

func runPagerTests() {
    var lock = AxisLock()
    check(lock.update(translation: CGSize(width: 3, height: 2)) == nil, "axis undecided below threshold")
    check(lock.update(translation: CGSize(width: 2, height: -8)) == .vertical, "vertical decided")
    check(lock.update(translation: CGSize(width: 90, height: -9)) == .vertical, "axis stays locked")
    lock.reset()
    check(lock.update(translation: CGSize(width: -7, height: 3)) == .horizontal, "horizontal decided")
    lock.reset()
    check(lock.update(translation: CGSize(width: 5, height: 5)) == nil, "diagonal under threshold is undecided")

    check(PagerMath.rubberBand(0, limit: 100) == 0, "no overshoot, no band")
    let band = PagerMath.rubberBand(50, limit: 100)
    check(band > 0 && band < 50, "rubber band resists")
    check(PagerMath.rubberBand(-50, limit: 100) == -band, "rubber band is symmetric")
    check(PagerMath.rubberBand(10_000, limit: 100) < 100, "rubber band is bounded by limit")
    check(PagerMath.resisted(40, maxOffset: 100, limit: 50) == 40, "inside range is untouched")
    check(PagerMath.resisted(-30, maxOffset: 100, limit: 50) < 0, "past the start resists")
    check(PagerMath.resisted(130, maxOffset: 100, limit: 50) > 100, "past the end resists")
    check(PagerMath.resisted(130, maxOffset: 100, limit: 50) < 130, "past the end resists less than 1:1")

    check(PagerMath.snappedPage(from: 0, translation: -20, predictedEnd: -20, pageHeight: 100, pageCount: 2) == 0,
          "small drag stays")
    check(PagerMath.snappedPage(from: 0, translation: -20, predictedEnd: -80, pageHeight: 100, pageCount: 2) == 1,
          "flick up goes to page 2")
    check(PagerMath.snappedPage(from: 0, translation: -60, predictedEnd: -60, pageHeight: 100, pageCount: 2) == 1,
          "drag past half goes to page 2")
    check(PagerMath.snappedPage(from: 1, translation: 80, predictedEnd: 80, pageHeight: 100, pageCount: 2) == 0,
          "flick down goes back")
    check(PagerMath.snappedPage(from: 1, translation: -80, predictedEnd: -300, pageHeight: 100, pageCount: 2) == 1,
          "no page past the last")
    check(PagerMath.snappedPage(from: 0, translation: 80, predictedEnd: 300, pageHeight: 100, pageCount: 2) == 0,
          "no page before the first")
    check(PagerMath.snappedPage(from: 0, translation: -90, predictedEnd: -900, pageHeight: 100, pageCount: 5) == 1,
          "a flick moves at most one page")

    check(PagerMath.clamp(-5, maxOffset: 100) == 0 && PagerMath.clamp(120, maxOffset: 100) == 100, "clamps")
    check(PagerMath.clamp(5, maxOffset: -3) == 0, "negative max clamps to 0")
    check(PagerMath.settledOffset(from: 10, predictedEnd: -50, maxOffset: 100) == 60, "momentum carries on")
    check(PagerMath.settledOffset(from: 90, predictedEnd: -50, maxOffset: 100) == 100, "momentum clamps at the end")
    check(PagerMath.settledOffset(from: 10, predictedEnd: 50, maxOffset: 100) == 0, "momentum clamps at the start")
    check(PagerMath.maxStripOffset(cardCount: 7, spacing: 10) == 60, "7 cards span 6 gaps")
    check(PagerMath.maxStripOffset(cardCount: 0, spacing: 10) == 0, "no cards, no scroll")
}
