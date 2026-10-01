import CoreGraphics

enum PagerAxis: Equatable {
    case horizontal, vertical
}

/// Decides, once per drag, whether the gesture is horizontal or vertical, and then keeps that axis.
struct AxisLock: Equatable {
    /// Travel (pt) before the axis is decided.
    static let threshold: CGFloat = 6

    private(set) var axis: PagerAxis?

    /// Feed the total translation of the drag so far. Returns the locked axis, or nil while undecided.
    @discardableResult
    mutating func update(translation: CGSize) -> PagerAxis? {
        if axis == nil {
            let dx = abs(translation.width), dy = abs(translation.height)
            guard max(dx, dy) >= Self.threshold else { return nil }
            axis = dx > dy ? .horizontal : .vertical
        }
        return axis
    }

    mutating func reset() { axis = nil }
}

/// Pure gesture maths for the pager: page snapping, rubber-banding and horizontal momentum.
enum PagerMath {
    /// Rubber-band resistance: how far the content follows a drag that is `overshoot` past an edge.
    static func rubberBand(_ overshoot: CGFloat, limit: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        guard limit > 0 else { return 0 }
        let x = abs(overshoot)
        let resisted = (1 - 1 / (x * coefficient / limit + 1)) * limit
        return overshoot < 0 ? -resisted : resisted
    }

    /// Maps a raw offset to one that resists past `0...maxOffset`.
    static func resisted(_ offset: CGFloat, maxOffset: CGFloat, limit: CGFloat) -> CGFloat {
        if offset < 0 { return rubberBand(offset, limit: limit) }
        if offset > maxOffset { return maxOffset + rubberBand(offset - maxOffset, limit: limit) }
        return offset
    }

    static func clamp(_ offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
        min(max(offset, 0), max(maxOffset, 0))
    }

    /// Page to settle on after a vertical drag. `translation` and `predictedEnd` are the drag's vertical
    /// values (negative = up). A flick can move at most one page.
    static func snappedPage(from page: Int, translation: CGFloat, predictedEnd: CGFloat,
                            pageHeight: CGFloat, pageCount: Int) -> Int {
        guard pageHeight > 0, pageCount > 0 else { return 0 }
        let projected = (CGFloat(page) * pageHeight - predictedEnd) / pageHeight
        let target = Int(projected.rounded())
        let limited = min(max(target, page - 1), page + 1)
        return min(max(limited, 0), pageCount - 1)
    }

    /// Where a horizontal drag ends up: the momentum end point, clamped to the content bounds.
    static func settledOffset(from start: CGFloat, predictedEnd: CGFloat, maxOffset: CGFloat) -> CGFloat {
        clamp(start - predictedEnd, maxOffset: maxOffset)
    }

    /// Largest scroll offset of the day strip.
    static func maxStripOffset(cardCount: Int, spacing: CGFloat) -> CGFloat {
        CGFloat(max(cardCount - 1, 0)) * spacing
    }
}
