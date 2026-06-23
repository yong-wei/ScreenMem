import Foundation

public struct RestoreReportViewModel: Equatable, Sendable {
    public let summary: String
    public let rows: [RestoreReportRow]

    public init(report: RestoreReport?) {
        guard let report else {
            self.summary = "No recent restore"
            self.rows = []
            return
        }

        let restoredCount = report.restoredWindows.count + report.lateRestoredWindows.count
        let skippedCount = report.skippedWindows.count + report.lateSkippedWindows.count
        let failedCount = report.failedWindows.count
        self.summary = "Restored \(restoredCount), skipped \(skippedCount), failed \(failedCount)"
        self.rows = report.restoredWindows.map {
            RestoreReportRow(title: $0.identity.titleHint ?? "Untitled Window", outcome: "Restored")
        } + report.lateRestoredWindows.map {
            RestoreReportRow(title: $0.identity.titleHint ?? "Untitled Window", outcome: "Late Restored")
        } + report.skippedWindows.map {
            RestoreReportRow(title: $0.identity?.titleHint ?? "Window", outcome: "Skipped: \($0.reason.rawValue)")
        } + report.lateSkippedWindows.map {
            RestoreReportRow(title: $0.identity?.titleHint ?? "Window", outcome: "Late Skipped: \($0.reason.rawValue)")
        } + report.failedWindows.map {
            RestoreReportRow(title: $0.identity.titleHint ?? "Untitled Window", outcome: "Failed: \($0.reason.rawValue)")
        }
    }
}

public struct RestoreReportRow: Equatable, Sendable {
    public let title: String
    public let outcome: String

    public init(title: String, outcome: String) {
        self.title = title
        self.outcome = outcome
    }
}
