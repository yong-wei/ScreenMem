import Foundation

public struct DisplayIdentity: Codable, Equatable, Sendable {
    public let stableID: String
    public let isBuiltIn: Bool
    public let name: String
    public let vendorID: UInt32?
    public let productID: UInt32?
    public let serialNumber: UInt32?
    public let nominalPixelSize: DisplaySize
    public let backingScaleFactor: Double

    public init(
        isBuiltIn: Bool,
        name: String,
        vendorID: UInt32?,
        productID: UInt32?,
        serialNumber: UInt32?,
        nominalPixelSize: DisplaySize,
        backingScaleFactor: Double
    ) {
        self.isBuiltIn = isBuiltIn
        self.name = name
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        self.nominalPixelSize = nominalPixelSize
        self.backingScaleFactor = backingScaleFactor
        self.stableID = Self.makeStableID(
            isBuiltIn: isBuiltIn,
            name: name,
            vendorID: vendorID,
            productID: productID,
            serialNumber: serialNumber,
            nominalPixelSize: nominalPixelSize,
            backingScaleFactor: backingScaleFactor
        )
    }

    private static func makeStableID(
        isBuiltIn: Bool,
        name: String,
        vendorID: UInt32?,
        productID: UInt32?,
        serialNumber: UInt32?,
        nominalPixelSize: DisplaySize,
        backingScaleFactor: Double
    ) -> String {
        [
            "builtin:\(isBuiltIn ? 1 : 0)",
            "vendor:\(vendorID.map(String.init) ?? "unknown")",
            "product:\(productID.map(String.init) ?? "unknown")",
            "serial:\(serialNumber.map(String.init) ?? "unknown")",
            "name:\(name.trimmingCharacters(in: .whitespacesAndNewlines))",
            "pixels:\(nominalPixelSize.width)x\(nominalPixelSize.height)",
            "scale:\(String(format: "%.3f", backingScaleFactor))"
        ].joined(separator: "|")
    }
}

public struct DisplaySnapshot: Codable, Equatable, Sendable {
    public let identity: DisplayIdentity
    public let frame: DisplayRect
    public let visibleFrame: DisplayRect
    public let isMain: Bool
    public let orderIndex: Int

    public init(
        identity: DisplayIdentity,
        frame: DisplayRect,
        visibleFrame: DisplayRect,
        isMain: Bool,
        orderIndex: Int
    ) {
        self.identity = identity
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.isMain = isMain
        self.orderIndex = orderIndex
    }
}

public enum DisplaySetFingerprint {
    public static func exact(for identities: [DisplayIdentity]) -> String {
        identities
            .map(\.stableID)
            .sorted()
            .joined(separator: "\n")
    }

    public static func exact(for snapshots: [DisplaySnapshot]) -> String {
        exact(for: snapshots.map(\.identity))
    }
}
