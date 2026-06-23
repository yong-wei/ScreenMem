import Foundation

public struct NormalizedRect: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum WindowGeometryNormalizer {
    public static func normalize(_ windowFrame: WindowRect, in visibleFrame: DisplayRect) -> NormalizedRect {
        let safeWidth = max(visibleFrame.width, 1)
        let safeHeight = max(visibleFrame.height, 1)

        return NormalizedRect(
            x: clamp((windowFrame.x - visibleFrame.x) / safeWidth),
            y: clamp((windowFrame.y - visibleFrame.y) / safeHeight),
            width: clamp(windowFrame.width / safeWidth),
            height: clamp(windowFrame.height / safeHeight)
        )
    }

    public static func denormalize(_ normalizedRect: NormalizedRect, in visibleFrame: DisplayRect) -> WindowRect {
        let width = min(clamp(normalizedRect.width) * visibleFrame.width, visibleFrame.width)
        let height = min(clamp(normalizedRect.height) * visibleFrame.height, visibleFrame.height)
        let rawX = visibleFrame.x + clamp(normalizedRect.x) * visibleFrame.width
        let rawY = visibleFrame.y + clamp(normalizedRect.y) * visibleFrame.height
        let maxX = visibleFrame.x + visibleFrame.width - width
        let maxY = visibleFrame.y + visibleFrame.height - height

        return WindowRect(
            x: min(max(rawX, visibleFrame.x), maxX),
            y: min(max(rawY, visibleFrame.y), maxY),
            width: width,
            height: height
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
