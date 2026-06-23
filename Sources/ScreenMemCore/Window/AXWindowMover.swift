import ApplicationServices
import Foundation

public enum AXWindowMover {
    public static func move(_ element: AXUIElement, to frame: WindowRect) -> WindowMoveResult {
        var point = CGPoint(x: frame.x, y: frame.y)
        var size = CGSize(width: frame.width, height: frame.height)
        guard let positionValue = AXValueCreate(.cgPoint, &point),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return .rejected
        }

        let sizeResult = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        let positionResult = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue)
        return sizeResult == .success && positionResult == .success ? .moved : .rejected
    }
}
