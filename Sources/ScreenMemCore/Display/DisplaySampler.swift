import AppKit
import CoreGraphics
import Foundation

public enum DisplaySampler {
    @MainActor
    public static func currentSnapshots() -> [DisplaySnapshot] {
        NSScreen.screens.enumerated().map { index, screen in
            let displayID = screen.displayID
            let pixelSize = DisplaySize(
                width: Int(CGDisplayPixelsWide(displayID)),
                height: Int(CGDisplayPixelsHigh(displayID))
            )
            let identity = DisplayIdentity(
                isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
                name: screen.localizedName,
                vendorID: availableIdentifier(CGDisplayVendorNumber(displayID)),
                productID: availableIdentifier(CGDisplayModelNumber(displayID)),
                serialNumber: availableIdentifier(CGDisplaySerialNumber(displayID)),
                nominalPixelSize: pixelSize,
                backingScaleFactor: Double(screen.backingScaleFactor)
            )

            return DisplaySnapshot(
                identity: identity,
                frame: DisplayRect(screen.frame),
                visibleFrame: DisplayRect(screen.visibleFrame),
                isMain: screen === NSScreen.main,
                orderIndex: index
            )
        }
    }

    private static func availableIdentifier(_ value: UInt32) -> UInt32? {
        value == 0 ? nil : value
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? CGMainDisplayID()
    }
}

private extension DisplayRect {
    init(_ rect: NSRect) {
        self.init(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }
}
