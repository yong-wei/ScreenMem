import Foundation

public enum ScreenMemFixtures {
    public static func display(_ suffix: String, builtIn: Bool = false) -> DisplayIdentity {
        DisplayIdentity(
            isBuiltIn: builtIn,
            name: "Display \(suffix)",
            vendorID: 100,
            productID: 200,
            serialNumber: UInt32(suffix.unicodeScalars.first?.value ?? 0),
            nominalPixelSize: DisplaySize(width: 1920, height: 1080),
            backingScaleFactor: 2.0
        )
    }

    public static func displaySnapshot(
        _ identity: DisplayIdentity,
        orderIndex: Int,
        x: Double = 0,
        y: Double = 0,
        width: Double = 1440,
        height: Double = 900
    ) -> DisplaySnapshot {
        DisplaySnapshot(
            identity: identity,
            frame: DisplayRect(x: x, y: y, width: width, height: height),
            visibleFrame: DisplayRect(x: x, y: y, width: width, height: height),
            isMain: orderIndex == 0,
            orderIndex: orderIndex
        )
    }

    public static func window(
        title: String,
        processIdentifier: Int32 = 300,
        ordinal: Int = 0,
        frame: WindowRect = WindowRect(x: 100, y: 100, width: 400, height: 300)
    ) -> WindowSnapshot {
        WindowSnapshot(
            appName: "Fixture App",
            bundleIdentifier: "dev.screenmem.fixture",
            processIdentifier: processIdentifier,
            appLocalOrdinal: ordinal,
            role: "AXWindow",
            subrole: "AXStandardWindow",
            titleHint: title,
            frame: frame,
            isMinimized: false,
            canMove: true,
            canResize: true
        )
    }

    public static func profile(
        display: DisplayIdentity,
        states: [WindowState] = [],
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
        createdAt: Date = Date(timeIntervalSince1970: 1)
    ) -> Profile {
        Profile(
            id: id,
            name: "Fixture Profile",
            createdAt: createdAt,
            displayFingerprint: DisplaySetFingerprint.exact(for: [display]),
            displays: [display],
            windowStates: states
        )
    }
}
